<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>

<%!
    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private boolean isEastMalaysia(String region) {
        return "EAST".equalsIgnoreCase(region) || "Sabah/Sarawak".equalsIgnoreCase(region);
    }

    private double calcShipping(String region, int itemCount) {
        if (itemCount <= 0) return 0.00;
        if (isEastMalaysia(region)) {
            return 15.00 + ((itemCount - 1) * 5.00);
        }
        return 8.00 + ((itemCount - 1) * 3.00);
    }
%>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?msg=Please login first");
        return;
    }

    int customerId = Integer.parseInt(session.getAttribute("userId").toString());

    ArrayList<Integer> selectedIds = new ArrayList<Integer>();
    String idsParam = request.getParameter("ids");
    String singleId = request.getParameter("id");
    String addressIdParam = request.getParameter("addressId");
    String simulatorApproved = request.getParameter("simulatorApproved");
    String paymentMethod = request.getParameter("paymentMethod") == null ? "" : request.getParameter("paymentMethod").trim();
    String paymentRefParam = request.getParameter("paymentRef") == null ? "" : request.getParameter("paymentRef").trim();

    if (idsParam != null && !idsParam.trim().isEmpty()) {
        String[] parts = idsParam.split(",");
        for (String part : parts) {
            try {
                int val = Integer.parseInt(part.trim());
                if (!selectedIds.contains(val)) selectedIds.add(val);
            } catch (Exception ignore) {}
        }
    }

    if (selectedIds.isEmpty() && singleId != null && !singleId.trim().isEmpty()) {
        try {
            selectedIds.add(Integer.parseInt(singleId.trim()));
        } catch (Exception ignore) {}
    }

    if (selectedIds.isEmpty()) {
        response.sendRedirect("order-history.jsp?msg=no_order_selected");
        return;
    }

    int addressId = 0;
    try {
        addressId = Integer.parseInt(addressIdParam);
    } catch (Exception ignore) {}

    if (addressId <= 0) {
        response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=address_required");
        return;
    }

    boolean validMethod = "FPX Online Banking".equalsIgnoreCase(paymentMethod)
            || "Debit/Credit Card".equalsIgnoreCase(paymentMethod)
            || "QR Transfer".equalsIgnoreCase(paymentMethod);

    if (!"yes".equalsIgnoreCase(simulatorApproved) || !validMethod) {
        response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=payment_not_approved");
        return;
    }

    String ref = paymentRefParam.length() > 0 ? paymentRefParam : "SIMPAY" + new java.util.Date().getTime();

    Connection conn = null;
    PreparedStatement psOrder = null;
    PreparedStatement psStock = null;
    PreparedStatement psCheck = null;
    PreparedStatement psUpdate = null;
    PreparedStatement psAddress = null;
    ResultSet rs = null;

    String shipName = "";
    String shipPhone = "";
    String shipAddress = "";
    String shipState = "";
    String shipRegion = "WEST";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();
        conn.setAutoCommit(false);

        psAddress = conn.prepareStatement("SELECT * FROM customer_addresses WHERE customer_id=? AND address_id=? FOR UPDATE");
        psAddress.setInt(1, customerId);
        psAddress.setInt(2, addressId);
        ResultSet addrRs = psAddress.executeQuery();

        if (!addrRs.next()) {
            addrRs.close();
            conn.rollback();
            response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=address_not_found");
            return;
        }

        shipName = addrRs.getString("recipient_name");
        shipPhone = addrRs.getString("phone");
        shipState = addrRs.getString("state");
        shipRegion = addrRs.getString("region") == null ? "WEST" : addrRs.getString("region");
        shipAddress = addrRs.getString("address_line1");
        if (!isBlank(addrRs.getString("address_line2"))) shipAddress += ", " + addrRs.getString("address_line2");
        shipAddress += ", " + addrRs.getString("postcode") + " " + addrRs.getString("city") + ", " + addrRs.getString("state");
        addrRs.close();
        psAddress.close();
        psAddress = null;

        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < selectedIds.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }

        String orderSql = "SELECT order_id, customer_id, shirt_fabric_name, skirt_fabric_name, "
                + "shirt_fabric_type, skirt_fabric_type, shirt_meter_used, skirt_meter_used, "
                + "stock_deducted, payment_status, order_status "
                + "FROM orders WHERE customer_id=? AND order_id IN (" + placeholders.toString() + ") FOR UPDATE";

        psOrder = conn.prepareStatement(orderSql);
        psOrder.setInt(1, customerId);
        for (int i = 0; i < selectedIds.size(); i++) {
            psOrder.setInt(i + 2, selectedIds.get(i));
        }

        rs = psOrder.executeQuery();

        ArrayList<Integer> payableIds = new ArrayList<Integer>();

        while (rs.next()) {
            int orderId = rs.getInt("order_id");
            String currentPaymentStatus = rs.getString("payment_status");
            String orderStatus = rs.getString("order_status");

            if ("paid".equalsIgnoreCase(currentPaymentStatus)
                    || "cancelled".equalsIgnoreCase(currentPaymentStatus)
                    || "cancelled".equalsIgnoreCase(orderStatus)) {
                continue;
            }

            payableIds.add(orderId);

            boolean stockDeducted = rs.getBoolean("stock_deducted");
            String shirtName = rs.getString("shirt_fabric_name");
            String skirtName = rs.getString("skirt_fabric_name");
            String shirtType = rs.getString("shirt_fabric_type");
            String skirtType = rs.getString("skirt_fabric_type");

            double shirtMeter = rs.getDouble("shirt_meter_used");
            double skirtMeter = rs.getDouble("skirt_meter_used");

            if (shirtMeter <= 0) shirtMeter = 2.00;
            if (skirtMeter <= 0) skirtMeter = 2.00;

            if (!stockDeducted) {
                if (isBlank(shirtType) || isBlank(shirtName)) {
                    conn.rollback();
                    response.sendRedirect("order-history.jsp?payment=failed&msg=missing_fabric_type");
                    return;
                }

                boolean hasBottomFabric = !isBlank(skirtType) && !isBlank(skirtName);
                boolean sameFabric = hasBottomFabric && shirtType.equals(skirtType) && shirtName.equals(skirtName);

                if (sameFabric) {
                    double totalMeter = shirtMeter + skirtMeter;

                    psCheck = conn.prepareStatement("SELECT stock_quantity FROM materials WHERE material_type=? AND material_name=? FOR UPDATE");
                    psCheck.setString(1, shirtType);
                    psCheck.setString(2, shirtName);
                    ResultSet stockRs = psCheck.executeQuery();

                    if (!stockRs.next() || stockRs.getDouble("stock_quantity") < totalMeter) {
                        stockRs.close();
                        conn.rollback();
                        response.sendRedirect("order-history.jsp?payment=failed&msg=insufficient_stock");
                        return;
                    }
                    stockRs.close();
                    psCheck.close();
                    psCheck = null;

                    psStock = conn.prepareStatement("UPDATE materials SET stock_quantity = stock_quantity - ? WHERE material_type=? AND material_name=?");
                    psStock.setDouble(1, totalMeter);
                    psStock.setString(2, shirtType);
                    psStock.setString(3, shirtName);
                    psStock.executeUpdate();
                    psStock.close();
                    psStock = null;
                } else {
                    psCheck = conn.prepareStatement("SELECT stock_quantity FROM materials WHERE material_type=? AND material_name=? FOR UPDATE");

                    psCheck.setString(1, shirtType);
                    psCheck.setString(2, shirtName);
                    ResultSet shirtStockRs = psCheck.executeQuery();
                    if (!shirtStockRs.next() || shirtStockRs.getDouble("stock_quantity") < shirtMeter) {
                        shirtStockRs.close();
                        conn.rollback();
                        response.sendRedirect("order-history.jsp?payment=failed&msg=insufficient_stock");
                        return;
                    }
                    shirtStockRs.close();

                    if (hasBottomFabric) {
                        psCheck.setString(1, skirtType);
                        psCheck.setString(2, skirtName);
                        ResultSet skirtStockRs = psCheck.executeQuery();
                        if (!skirtStockRs.next() || skirtStockRs.getDouble("stock_quantity") < skirtMeter) {
                            skirtStockRs.close();
                            conn.rollback();
                            response.sendRedirect("order-history.jsp?payment=failed&msg=insufficient_stock");
                            return;
                        }
                        skirtStockRs.close();
                    }

                    psCheck.close();
                    psCheck = null;

                    psStock = conn.prepareStatement("UPDATE materials SET stock_quantity = stock_quantity - ? WHERE material_type=? AND material_name=?");
                    psStock.setDouble(1, shirtMeter);
                    psStock.setString(2, shirtType);
                    psStock.setString(3, shirtName);
                    psStock.executeUpdate();

                    if (hasBottomFabric) {
                        psStock.setDouble(1, skirtMeter);
                        psStock.setString(2, skirtType);
                        psStock.setString(3, skirtName);
                        psStock.executeUpdate();
                    }
                    psStock.close();
                    psStock = null;
                }
            }
        }

        if (payableIds.isEmpty()) {
            conn.rollback();
            response.sendRedirect("order-history.jsp?payment=failed&msg=order_not_found");
            return;
        }

        double totalShippingFee = calcShipping(shipRegion, payableIds.size());
        double shippingPerOrder = totalShippingFee / payableIds.size();

        StringBuilder updatePlaceholders = new StringBuilder();
        for (int i = 0; i < payableIds.size(); i++) {
            if (i > 0) updatePlaceholders.append(",");
            updatePlaceholders.append("?");
        }

        String updateSql = "UPDATE orders SET payment_status=?, payment_method=?, payment_ref=?, bill_code=?, "
                + "order_status=?, progress_status=?, progress_note=?, progress_updated_at=NOW(), stock_deducted=?, "
                + "shipping_fee=?, shipping_address_id=?, shipping_recipient_name=?, shipping_phone=?, "
                + "shipping_address=?, shipping_state=?, shipping_region=? "
                + "WHERE customer_id=? AND order_id IN (" + updatePlaceholders.toString() + ")";

        psUpdate = conn.prepareStatement(updateSql);
        psUpdate.setString(1, "paid");
        psUpdate.setString(2, paymentMethod + " (Simulation)");
        psUpdate.setString(3, ref);
        psUpdate.setString(4, "PAYMENT_SIMULATOR");
        psUpdate.setString(5, "payment_confirmed");
        psUpdate.setString(6, "pending");
        psUpdate.setString(7, "Payment received. Waiting for tailor to start sewing task.");
        psUpdate.setBoolean(8, true);
        psUpdate.setDouble(9, shippingPerOrder);
        psUpdate.setInt(10, addressId);
        psUpdate.setString(11, shipName);
        psUpdate.setString(12, shipPhone);
        psUpdate.setString(13, shipAddress);
        psUpdate.setString(14, shipState);
        psUpdate.setString(15, shipRegion);
        psUpdate.setInt(16, customerId);
        for (int i = 0; i < payableIds.size(); i++) {
            psUpdate.setInt(i + 17, payableIds.get(i));
        }
        psUpdate.executeUpdate();

        conn.commit();
        response.sendRedirect("order-history.jsp?payment=success&ref=" + ref);
    } catch (Exception e) {
        try { if (conn != null) conn.rollback(); } catch (Exception ignore) {}
        e.printStackTrace();
        response.sendRedirect("order-history.jsp?payment=failed");
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (psOrder != null) psOrder.close(); } catch (Exception ignore) {}
        try { if (psStock != null) psStock.close(); } catch (Exception ignore) {}
        try { if (psCheck != null) psCheck.close(); } catch (Exception ignore) {}
        try { if (psUpdate != null) psUpdate.close(); } catch (Exception ignore) {}
        try { if (psAddress != null) psAddress.close(); } catch (Exception ignore) {}
        try { if (conn != null) conn.close(); } catch (Exception ignore) {}
    }
%>
