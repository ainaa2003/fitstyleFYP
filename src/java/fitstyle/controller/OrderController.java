/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package fitstyle.controller;

import fitstyle.dao.DesignDAO;
import fitstyle.dao.OrderDAO;
import fitstyle.model.Material;
import fitstyle.util.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/OrderController")
public class OrderController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        HttpSession session = request.getSession();

        // Inisialisasi DAO
        DesignDAO designDAO = new DesignDAO();

        // --- CASE 1: CHECK LOGIN UNTUK TEMPAH ---
        if ("checkLogin".equals(action)) {
            String designID = request.getParameter("designID");
            String basePrice = request.getParameter("basePrice");

            // 1. Cek Login
            if (session.getAttribute("userId") == null) {
                session.setAttribute("pendingDesignID", designID);
                session.setAttribute("pendingBasePrice", basePrice);
                response.sendRedirect("login.jsp?msg=Sila_login_dahulu_untuk_menempah");
            } else if ("tailor".equals(session.getAttribute("userRole"))) {
                // Tailor/owner can preview designs only. Tailor cannot create customer orders.
                response.sendRedirect("browse-designs.jsp?msg=tailor_preview_only");
            } else {
                try {
                    List<Material> materials = designDAO.getAllMaterials();
                    request.setAttribute("materialList", materials);
                    request.getRequestDispatcher("order-form.jsp").forward(request, response);
                } catch (Exception e) {
                    e.printStackTrace();
                    response.sendRedirect("index.jsp?msg=Error_Database");
                }
            }
        } // --- CASE 2: CANCEL ORDER BEFORE PAYMENT ---
        else if ("cancel".equals(action)) {
            String idStr = request.getParameter("id");
            Object userObj = session.getAttribute("userId");

            if (idStr == null || userObj == null) {
                response.sendRedirect("order-history.jsp?msg=failed");
                return;
            }

            Connection conn = null;
            PreparedStatement ps = null;

            try {
                int orderId = Integer.parseInt(idStr);
                int customerId = Integer.parseInt(userObj.toString());

                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DBConnection.getConnection();

                String sql = "UPDATE orders SET order_status='cancelled', payment_status='cancelled' "
                        + "WHERE order_id=? AND customer_id=? AND payment_status <> 'paid'";
                ps = conn.prepareStatement(sql);
                ps.setInt(1, orderId);
                ps.setInt(2, customerId);

                int result = ps.executeUpdate();

                if (result > 0) {
                    response.sendRedirect("order-history.jsp?msg=cancelled");
                } else {
                    response.sendRedirect("order-history.jsp?msg=cancel_not_allowed");
                }
            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect("order-history.jsp?msg=failed");
            } finally {
                try { if (ps != null) ps.close(); } catch (Exception ignore) {}
                try { if (conn != null) conn.close(); } catch (Exception ignore) {}
            }
        } // --- CASE 3: DELETE ORDER (LEGACY, ONLY BEFORE PAYMENT) ---
        else if ("delete".equals(action)) {
            String idStr = request.getParameter("id");
            Object userObj = session.getAttribute("userId");

            if (idStr != null && userObj != null) {
                Connection conn = null;
                PreparedStatement ps = null;
                try {
                    int orderId = Integer.parseInt(idStr);
                    int customerId = Integer.parseInt(userObj.toString());

                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = DBConnection.getConnection();

                    String sql = "DELETE FROM orders WHERE order_id=? AND customer_id=? AND payment_status <> 'paid'";
                    ps = conn.prepareStatement(sql);
                    ps.setInt(1, orderId);
                    ps.setInt(2, customerId);

                    int result = ps.executeUpdate();

                    if (result > 0) {
                        response.sendRedirect("order-history.jsp?msg=deleted");
                    } else {
                        response.sendRedirect("order-history.jsp?msg=cancel_not_allowed");
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    response.sendRedirect("order-history.jsp?msg=failed");
                } finally {
                    try { if (ps != null) ps.close(); } catch (Exception ignore) {}
                    try { if (conn != null) conn.close(); } catch (Exception ignore) {}
                }
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String action = request.getParameter("action");
        System.out.println(">>> DEBUG: Masuk doPost OrderController. Action: " + action);

        if ("submitOrder".equals(action)) {
            HttpSession session = request.getSession();

            try {
                String orderToken = request.getParameter("orderToken");
                Object sessionToken = session.getAttribute("orderSubmitToken");
                if (orderToken == null || sessionToken == null || !orderToken.equals(sessionToken.toString())) {
                    response.sendRedirect("order-history.jsp?msg=duplicate_prevented");
                    return;
                }
                session.removeAttribute("orderSubmitToken");

                String designID = request.getParameter("designID");
                String shirtPattern = request.getParameter("shirtPattern");
                String skirtPattern = request.getParameter("skirtPattern");
                String topSize = request.getParameter("topSize");
                String bottomSize = request.getParameter("bottomSize");
                String fitPreference = request.getParameter("fitPreference");
                String height = request.getParameter("heightCm");
                String weight = request.getParameter("weightKg");
                String notes = request.getParameter("specialRequest");
                String totalPrice = request.getParameter("totalPrice");
                int decorationId = parseIntOrZero(request.getParameter("decorationId"));
                String decorationArea = joinValues(request.getParameterValues("decorationArea"));
                String decorationNotes = request.getParameter("decorationNotes");
                String shirtExtraMeterStr = request.getParameter("shirtExtraMeter");
                String skirtExtraMeterStr = request.getParameter("skirtExtraMeter");

                double shirtExtraMeter = parseDoubleOrZero(shirtExtraMeterStr);
                double skirtExtraMeter = parseDoubleOrZero(skirtExtraMeterStr);
                double shirtMeterUsed = 2.0 + shirtExtraMeter;
                double skirtMeterUsed = 2.0 + skirtExtraMeter;

                boolean isSynced = request.getParameter("syncFabric") != null;
                if (isSynced) {
                    skirtPattern = shirtPattern;
                }

                Object uId = session.getAttribute("userId");
                if (uId == null) {
                    response.sendRedirect("login.jsp?msg=Sila_login_semula");
                    return;
                }

                if ("tailor".equals(session.getAttribute("userRole"))) {
                    response.sendRedirect("browse-designs.jsp?msg=tailor_preview_only");
                    return;
                }

                String shirtFabricType = request.getParameter("shirtFabricType");
                String skirtFabricType = request.getParameter("skirtFabricType");

                boolean isTopOnlyDesign = isTopOnlyDesign(designID);
                if (isTopOnlyDesign) {
                    skirtFabricType = null;
                    skirtPattern = null;
                    bottomSize = null;
                    skirtExtraMeter = 0.0;
                    skirtMeterUsed = 0.0;
                    isSynced = false;
                } else if (isSynced) {
                    skirtFabricType = shirtFabricType;
                }

                if (isBlank(designID) || isBlank(shirtFabricType) || isBlank(shirtPattern)
                        || isBlank(topSize) || (!isTopOnlyDesign && isBlank(bottomSize)) || isBlank(totalPrice)) {
                    response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                            + "&basePrice=" + safe(request.getParameter("basePrice"))
                            + "&msg=missing_required");
                    return;
                }

                if (!isTopOnlyDesign && !isSynced && (isBlank(skirtFabricType) || isBlank(skirtPattern))) {
                    response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                            + "&basePrice=" + safe(request.getParameter("basePrice"))
                            + "&msg=missing_bottom_material");
                    return;
                }

                double serverTotalPrice = Double.parseDouble(totalPrice);
                double basePriceValue = parseDoubleOrZero(request.getParameter("basePrice"));

                Connection stockConn = null;
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    stockConn = DBConnection.getConnection();

                    FabricInfo shirtInfo = getFabricInfo(stockConn, shirtFabricType, shirtPattern);
                    DecorationInfo decorationInfo = getDecorationInfo(stockConn, decorationId);
                    String decorationName = decorationInfo != null ? decorationInfo.name : null;
                    double decorationPrice = decorationInfo != null ? decorationInfo.price : 0.0;
                    if (decorationId <= 0) { decorationArea = null; decorationNotes = null; }
                    FabricInfo skirtInfo = isTopOnlyDesign ? null : (isSynced ? shirtInfo : getFabricInfo(stockConn, skirtFabricType, skirtPattern));

                    if (shirtInfo == null || (!isTopOnlyDesign && skirtInfo == null)) {
                        response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                                + "&basePrice=" + safe(request.getParameter("basePrice"))
                                + "&msg=insufficient_stock");
                        return;
                    }

                    if (isTopOnlyDesign) {
                        if (shirtInfo.stockQuantity < shirtMeterUsed) {
                            response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                                    + "&basePrice=" + safe(request.getParameter("basePrice"))
                                    + "&msg=insufficient_stock");
                            return;
                        }
                    } else if (isSameFabric(shirtFabricType, shirtPattern, skirtFabricType, skirtPattern)) {
                        double totalMeterNeeded = shirtMeterUsed + skirtMeterUsed;
                        if (shirtInfo.stockQuantity < totalMeterNeeded) {
                            response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                                    + "&basePrice=" + safe(request.getParameter("basePrice"))
                                    + "&msg=insufficient_stock");
                            return;
                        }
                    } else {
                        if (shirtInfo.stockQuantity < shirtMeterUsed || skirtInfo.stockQuantity < skirtMeterUsed) {
                            response.sendRedirect("order-form.jsp?designID=" + safe(designID)
                                    + "&basePrice=" + safe(request.getParameter("basePrice"))
                                    + "&msg=insufficient_stock");
                            return;
                        }
                    }

                    double shirtMaterialCost = shirtInfo.priceForTwoMeters + (shirtExtraMeter * (shirtInfo.priceForTwoMeters / 2.0));
                    double skirtMaterialCost = isTopOnlyDesign ? 0.0 : (skirtInfo.priceForTwoMeters + (skirtExtraMeter * (skirtInfo.priceForTwoMeters / 2.0)));
                    serverTotalPrice = basePriceValue + shirtMaterialCost + skirtMaterialCost + decorationPrice;
                    totalPrice = String.format(java.util.Locale.US, "%.2f", serverTotalPrice);
                } finally {
                    try { if (stockConn != null) stockConn.close(); } catch (Exception ignore) {}
                }

                int customerId = Integer.parseInt(uId.toString());

                OrderDAO dao = new OrderDAO();
                int newOrderId = dao.createOrder(
                        customerId,
                        Integer.parseInt(designID),
                        shirtPattern,
                        skirtPattern,
                        shirtFabricType,
                        skirtFabricType,
                        shirtMeterUsed,
                        skirtMeterUsed,
                        topSize,
                        bottomSize,
                        fitPreference,
                        height,
                        weight,
                        notes,
                        Double.parseDouble(totalPrice),
                        decorationId,
                        decorationId > 0 ? getDecorationNameById(decorationId) : null,
                        decorationId > 0 ? decorationArea : null,
                        decorationId > 0 ? decorationNotes : null,
                        decorationId > 0 ? getDecorationPriceById(decorationId) : 0.0
                );

                if (newOrderId > 0) {
                    session.setAttribute("designID", designID);
                    session.setAttribute("shirtFabricType", request.getParameter("shirtFabricType"));
                    session.setAttribute("shirtPattern", shirtPattern);
                    session.setAttribute("skirtFabricType", request.getParameter("skirtFabricType"));
                    session.setAttribute("skirtPattern", skirtPattern);
                    session.setAttribute("shirtExtraMeter", String.valueOf(shirtExtraMeter));
                    session.setAttribute("skirtExtraMeter", String.valueOf(skirtExtraMeter));

                    session.setAttribute("topSize", topSize);
                    session.setAttribute("bottomSize", bottomSize);
                    session.setAttribute("fitPreference", fitPreference);
                    session.setAttribute("heightCm", height);
                    session.setAttribute("weightKg", weight);
                    session.setAttribute("specialRequest", notes);

                    session.setAttribute("totalPrice", totalPrice);
                    session.setAttribute("basePrice", request.getParameter("basePrice"));
                    session.setAttribute("postageFee", "8.00");
                    session.setAttribute("orderId", newOrderId);

                    response.sendRedirect("payment.jsp?id=" + newOrderId);
                } else {
                    response.sendRedirect("order-form.jsp?msg=Gagal_Simpan_DB");
                }

            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect("order-form.jsp?msg=Error_Sistem");
            }
        } // --- DI SINI BAHAGIAN UPDATE YANG DITAMBAH ---
        else if ("updateOrder".equals(action)) {

            int orderId = Integer.parseInt(request.getParameter("orderId"));

            String topSize = request.getParameter("topSize");
            String bottomSize = request.getParameter("bottomSize");
            String fitPreference = request.getParameter("fitPreference");
            String heightCm = request.getParameter("heightCm");
            String weightKg = request.getParameter("weightKg");
            String specialRequest = request.getParameter("specialRequest");
            String totalPrice = request.getParameter("totalPrice");
            int decorationId = parseIntOrZero(request.getParameter("decorationId"));
            String decorationArea = joinValues(request.getParameterValues("decorationArea"));
            String decorationNotes = request.getParameter("decorationNotes");
            String shirtExtraMeterStr = request.getParameter("shirtExtraMeter");
            String skirtExtraMeterStr = request.getParameter("skirtExtraMeter");

            double shirtExtraMeter = parseDoubleOrZero(shirtExtraMeterStr);
            double skirtExtraMeter = parseDoubleOrZero(skirtExtraMeterStr);
            double shirtMeterUsed = 2.0 + shirtExtraMeter;
            double skirtMeterUsed = 2.0 + skirtExtraMeter;

            String shirtPattern = request.getParameter("shirtPattern");
            String skirtPattern = request.getParameter("skirtPattern");

            boolean isSynced = request.getParameter("syncFabric") != null;
            if (isSynced) {
                skirtPattern = shirtPattern;
            }

            HttpSession session = request.getSession();
            if ("tailor".equals(session.getAttribute("userRole"))) {
                response.sendRedirect("browse-designs.jsp?msg=tailor_preview_only");
                return;
            }

            String designID = request.getParameter("designID");
            String basePrice = request.getParameter("basePrice");
            String shirtFabricType = request.getParameter("shirtFabricType");
            String skirtFabricType = request.getParameter("skirtFabricType");

            boolean isTopOnlyDesign = isTopOnlyDesign(designID);
            if (isTopOnlyDesign) {
                skirtFabricType = null;
                skirtPattern = null;
                bottomSize = null;
                skirtExtraMeter = 0.0;
                skirtMeterUsed = 0.0;
                isSynced = false;
            } else if (isSynced) {
                skirtFabricType = shirtFabricType;
            }

            if (isBlank(shirtFabricType) || isBlank(shirtPattern)
                    || isBlank(topSize) || (!isTopOnlyDesign && isBlank(bottomSize)) || isBlank(totalPrice)) {
                response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=missing_required");
                return;
            }

            if (!isTopOnlyDesign && !isSynced && (isBlank(skirtFabricType) || isBlank(skirtPattern))) {
                response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=missing_bottom_material");
                return;
            }

            Connection conn = null;
            PreparedStatement psCheck = null;
            PreparedStatement psUpdate = null;
            ResultSet rs = null;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DBConnection.getConnection();

                // check status dulu
                psCheck = conn.prepareStatement("SELECT order_status FROM orders WHERE order_id=?");
                psCheck.setInt(1, orderId);
                rs = psCheck.executeQuery();

                if (!rs.next()) {
                    response.sendRedirect("order-history.jsp?msg=order_not_found");
                    return;
                }

                String status = rs.getString("order_status");
                if (!"waiting_for_payment".equals(status)) {
                    response.sendRedirect("order-history.jsp?msg=not_allowed");
                    return;
                }

                if (shirtPattern == null || shirtPattern.trim().isEmpty()
                        || (!isTopOnlyDesign && (skirtPattern == null || skirtPattern.trim().isEmpty()))) {
                    response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=material_required");
                    return;
                }

                double serverTotalPrice = Double.parseDouble(totalPrice);
                double basePriceValue = parseDoubleOrZero(basePrice);

                FabricInfo shirtInfo = getFabricInfo(conn, shirtFabricType, shirtPattern);
                DecorationInfo decorationInfo = getDecorationInfo(conn, decorationId);
                String decorationName = decorationInfo != null ? decorationInfo.name : null;
                double decorationPrice = decorationInfo != null ? decorationInfo.price : 0.0;
                if (decorationId <= 0) { decorationArea = null; decorationNotes = null; }
                FabricInfo skirtInfo = isTopOnlyDesign ? null : (isSynced ? shirtInfo : getFabricInfo(conn, skirtFabricType, skirtPattern));

                if (shirtInfo == null || (!isTopOnlyDesign && skirtInfo == null)) {
                    response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=insufficient_stock");
                    return;
                }

                if (isTopOnlyDesign) {
                    if (shirtInfo.stockQuantity < shirtMeterUsed) {
                        response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=insufficient_stock");
                        return;
                    }
                } else if (isSameFabric(shirtFabricType, shirtPattern, skirtFabricType, skirtPattern)) {
                    double totalMeterNeeded = shirtMeterUsed + skirtMeterUsed;
                    if (shirtInfo.stockQuantity < totalMeterNeeded) {
                        response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=insufficient_stock");
                        return;
                    }
                } else {
                    if (shirtInfo.stockQuantity < shirtMeterUsed || skirtInfo.stockQuantity < skirtMeterUsed) {
                        response.sendRedirect("order-form.jsp?editOrderId=" + orderId + "&msg=insufficient_stock");
                        return;
                    }
                }

                double shirtMaterialCost = shirtInfo.priceForTwoMeters + (shirtExtraMeter * (shirtInfo.priceForTwoMeters / 2.0));
                double skirtMaterialCost = isTopOnlyDesign ? 0.0 : (skirtInfo.priceForTwoMeters + (skirtExtraMeter * (skirtInfo.priceForTwoMeters / 2.0)));
                serverTotalPrice = basePriceValue + shirtMaterialCost + skirtMaterialCost + decorationPrice;
                totalPrice = String.format(java.util.Locale.US, "%.2f", serverTotalPrice);

                String sql = "UPDATE orders SET shirt_fabric_name=?, skirt_fabric_name=?, "
                        + "shirt_fabric_type=?, skirt_fabric_type=?, shirt_meter_used=?, skirt_meter_used=?, "
                        + "top_size=?, bottom_size=?, fit_preference=?, height_cm=?, weight_kg=?, special_request=?, total_price=?, "
                        + "decoration_id=?, decoration_name=?, decoration_area=?, decoration_notes=?, decoration_price=? "
                        + "WHERE order_id=?";

                psUpdate = conn.prepareStatement(sql);

                psUpdate.setString(1, shirtPattern);
                psUpdate.setString(2, skirtPattern);
                psUpdate.setString(3, shirtFabricType);
                psUpdate.setString(4, skirtFabricType);
                psUpdate.setDouble(5, shirtMeterUsed);
                psUpdate.setDouble(6, skirtMeterUsed);
                psUpdate.setString(7, topSize);
                psUpdate.setString(8, bottomSize);
                psUpdate.setString(9, fitPreference);

                if (heightCm == null || heightCm.trim().isEmpty()) {
                    psUpdate.setNull(10, java.sql.Types.DOUBLE);
                } else {
                    psUpdate.setDouble(10, Double.parseDouble(heightCm));
                }

                if (weightKg == null || weightKg.trim().isEmpty()) {
                    psUpdate.setNull(11, java.sql.Types.DOUBLE);
                } else {
                    psUpdate.setDouble(11, Double.parseDouble(weightKg));
                }

                psUpdate.setString(12, specialRequest);
                psUpdate.setDouble(13, Double.parseDouble(totalPrice));
                if (decorationId > 0) {
                    psUpdate.setInt(14, decorationId);
                } else {
                    psUpdate.setNull(14, java.sql.Types.INTEGER);
                }
                psUpdate.setString(15, decorationName);
                psUpdate.setString(16, decorationArea);
                psUpdate.setString(17, decorationNotes);
                psUpdate.setDouble(18, decorationPrice);
                psUpdate.setInt(19, orderId);

                psUpdate.executeUpdate();

                response.sendRedirect("order-history.jsp?msg=updated");

            } catch (Exception e) {
                e.printStackTrace();
                response.sendRedirect("order-history.jsp?msg=error_update");
            } finally {
                try {
                    if (rs != null) {
                        rs.close();
                    }
                } catch (Exception ignore) {
                }
                try {
                    if (psCheck != null) {
                        psCheck.close();
                    }
                } catch (Exception ignore) {
                }
                try {
                    if (psUpdate != null) {
                        psUpdate.close();
                    }
                } catch (Exception ignore) {
                }
                try {
                    if (conn != null) {
                        conn.close();
                    }
                } catch (Exception ignore) {
                }
            }
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String safe(String value) throws java.io.UnsupportedEncodingException {
        if (value == null) {
            return "";
        }
        return java.net.URLEncoder.encode(value, "UTF-8");
    }

    private double parseDoubleOrZero(String value) {
        try {
            if (value == null || value.trim().isEmpty()) {
                return 0.00;
            }
            return Double.parseDouble(value);
        } catch (Exception e) {
            return 0.00;
        }
    }

    private boolean isSameFabric(String type1, String name1, String type2, String name2) {
        return type1 != null && name1 != null && type2 != null && name2 != null
                && type1.equals(type2) && name1.equals(name2);
    }

    private FabricInfo getFabricInfo(Connection conn, String materialType, String materialName) throws Exception {
        String sql = "SELECT extra_price, stock_quantity FROM materials WHERE material_type=? AND material_name=? LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, materialType);
            ps.setString(2, materialName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    FabricInfo info = new FabricInfo();
                    info.priceForTwoMeters = rs.getDouble("extra_price");
                    info.stockQuantity = rs.getDouble("stock_quantity");
                    return info;
                }
            }
        }
        return null;
    }


    private boolean isTopOnlyDesign(String designID) {
        if (isBlank(designID)) {
            return false;
        }
        String sql = "SELECT size_guide_type FROM designs WHERE design_id=? LIMIT 1";
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection conn = DBConnection.getConnection();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, Integer.parseInt(designID));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String type = rs.getString("size_guide_type");
                        return "Kurta".equalsIgnoreCase(type) || "Jubah".equalsIgnoreCase(type);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }



    private String joinValues(String[] values) {
        if (values == null || values.length == 0) return null;
        StringBuilder sb = new StringBuilder();
        for (String v : values) {
            if (v != null && !v.trim().isEmpty()) {
                if (sb.length() > 0) sb.append(", ");
                sb.append(v.trim());
            }
        }
        return sb.length() == 0 ? null : sb.toString();
    }
    private int parseIntOrZero(String value) {
        try {
            if (value == null || value.trim().isEmpty()) return 0;
            return Integer.parseInt(value);
        } catch (Exception e) {
            return 0;
        }
    }

    private DecorationInfo getDecorationInfo(Connection conn, int decorationId) throws Exception {
        if (decorationId <= 0) return null;
        String sql = "SELECT decoration_name, price FROM decorations WHERE decoration_id=? AND is_active=1 LIMIT 1";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, decorationId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    DecorationInfo info = new DecorationInfo();
                    info.name = rs.getString("decoration_name");
                    info.price = rs.getDouble("price");
                    return info;
                }
            }
        }
        return null;
    }

    private String getDecorationNameById(int decorationId) {
        if (decorationId <= 0) return null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection conn = DBConnection.getConnection()) {
                DecorationInfo info = getDecorationInfo(conn, decorationId);
                return info != null ? info.name : null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    private double getDecorationPriceById(int decorationId) {
        if (decorationId <= 0) return 0.0;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection conn = DBConnection.getConnection()) {
                DecorationInfo info = getDecorationInfo(conn, decorationId);
                return info != null ? info.price : 0.0;
            }
        } catch (Exception e) {
            return 0.0;
        }
    }

    private static class DecorationInfo {
        String name;
        double price;
    }

    private static class FabricInfo {
        double priceForTwoMeters;
        double stockQuantity;
    }

}
