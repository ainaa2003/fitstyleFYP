<%--
    Document   : receipt
    Purpose    : Read-only receipt for paid customer orders
--%>

<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Receipt | FitStyle</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            body {
                background-color: #f8f9fa;
                font-family: 'Poppins', sans-serif;
                color: #043927;
            }
            .receipt-card {
                max-width: 680px;
                margin: 40px auto;
                border: none;
                border-radius: 18px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.10);
                overflow: hidden;
            }
            .receipt-header {
                background: #043927;
                color: #D4AF37;
                padding: 24px;
                text-align: center;
            }
            .receipt-line {
                border-top: 1px dashed #ccc;
                margin: 18px 0;
            }
            .label-text {
                color: #6c757d;
                font-size: 0.86rem;
            }
            @media print {
                .no-print { display: none; }
                body { background: white; }
                .receipt-card { box-shadow: none; margin: 0 auto; }
            }
        </style>
    </head>
    <body>
        <%@include file="includes/navbar.jsp"%>

        <%
            Integer userId = (Integer) session.getAttribute("userId"); 
            String currentUserRole = (String) session.getAttribute("userRole");

            if (userId == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            String idParam = request.getParameter("id");
            if (idParam == null || idParam.trim().isEmpty()) {
                response.sendRedirect("order-history.jsp");
                return;
            }

            int orderId = Integer.parseInt(idParam);
            double postage = 0.00;

            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            boolean found = false;
        %>

        <div class="container">
            <div class="card receipt-card">
                <div class="receipt-header">
                    <h2 class="mb-1" style="font-family:'Playfair Display', serif; font-weight:bold;">FitStyle</h2>
                    <div class="small">Official Payment Receipt</div>
                </div>

                <div class="card-body p-4">
                    <%
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            conn = fitstyle.util.DBConnection.getConnection();

                            String sql = "SELECT o.order_id, o.order_date, o.total_price, o.payment_status, o.payment_method, o.payment_ref, "
                                    + "o.shirt_fabric_name, o.skirt_fabric_name, o.top_size, o.bottom_size, o.fit_preference, "
                                    + "o.height_cm, o.weight_kg, o.special_request, o.progress_status, o.progress_note, "
                                    + "o.decoration_name, o.decoration_area, o.decoration_notes, COALESCE(o.decoration_price,0) AS decoration_price, "
                                    + "o.courier_name, o.tracking_number, o.tracking_updated_at, "
                                    + "COALESCE(o.shipping_fee, 0) AS receipt_shipping_fee, "
                                    + "COALESCE(o.shipping_region, '') AS receipt_shipping_region, "
                                    + "COALESCE(o.shipping_recipient_name, u.full_name) AS receipt_recipient_name, "
                                    + "COALESCE(o.shipping_phone, u.phone) AS receipt_recipient_phone, "
                                    + "COALESCE(o.shipping_address, u.address) AS receipt_delivery_address, "
                                    + "u.full_name, u.email, u.phone, u.address, d.design_name, d.base_price "
                                    + "FROM orders o "
                                    + "JOIN users u ON o.customer_id=u.user_id "
                                    + "LEFT JOIN designs d ON o.design_id=d.design_id "
                                    + "WHERE o.order_id=? ";

                            if (!"tailor".equals(currentUserRole)) {
                                sql += "AND o.customer_id=? ";
                            }

                            ps = conn.prepareStatement(sql);
                            ps.setInt(1, orderId);

                            if (!"tailor".equals(currentUserRole)) {
                                ps.setInt(2, userId);
                            }

                            rs = ps.executeQuery();

                            if (rs.next()) {
                                found = true;

                                String paymentStatus = rs.getString("payment_status");
                                double orderTotal = rs.getDouble("total_price");
                                double basePrice = rs.getDouble("base_price");
                                double materialCost = orderTotal - basePrice;

                                if (materialCost < 0) {
                                    materialCost = 0.00;
                                }

                                postage = rs.getDouble("receipt_shipping_fee");
                                double grandTotal = orderTotal + postage;

                                String receiptRecipientName = rs.getString("receipt_recipient_name");
                                String receiptRecipientPhone = rs.getString("receipt_recipient_phone");
                                String receiptDeliveryAddress = rs.getString("receipt_delivery_address");
                                String receiptShippingRegion = rs.getString("receipt_shipping_region");

                                if (receiptRecipientName == null || receiptRecipientName.trim().isEmpty()) {
                                    receiptRecipientName = rs.getString("full_name");
                                }
                                if (receiptRecipientPhone == null || receiptRecipientPhone.trim().isEmpty()) {
                                    receiptRecipientPhone = rs.getString("phone");
                                }
                                if (receiptDeliveryAddress == null || receiptDeliveryAddress.trim().isEmpty()) {
                                    receiptDeliveryAddress = rs.getString("address");
                                }
                    %>

                    <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
                        <div>
                            <div class="label-text">Receipt No.</div>
                            <h5 class="mb-0">#FS-<%= rs.getInt("order_id")%></h5>
                        </div>
                        <div class="text-end">
                            <span class="badge <%= "paid".equals(paymentStatus) ? "bg-success" : "bg-warning text-dark"%>">
                                <%= paymentStatus != null ? paymentStatus.toUpperCase() : "PENDING"%>
                            </span>
                            <div class="small text-muted mt-1"><%= rs.getTimestamp("order_date")%></div>
                        </div>
                    </div>

                    <div class="receipt-line"></div>

                    <h6 class="fw-bold mb-3"><i class="fas fa-user me-2"></i>Customer Details</h6>
                    <div class="row small mb-3">
                        <div class="col-md-6 mb-2"><span class="label-text">Name:</span><br><strong><%= rs.getString("full_name")%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Phone:</span><br><strong><%= rs.getString("phone") != null ? rs.getString("phone") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Email:</span><br><strong><%= rs.getString("email") != null ? rs.getString("email") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Receiver:</span><br><strong><%= receiptRecipientName != null && !receiptRecipientName.trim().isEmpty() ? receiptRecipientName : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Receiver Phone:</span><br><strong><%= receiptRecipientPhone != null && !receiptRecipientPhone.trim().isEmpty() ? receiptRecipientPhone : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Shipping Region:</span><br><strong><%= receiptShippingRegion != null && !receiptShippingRegion.trim().isEmpty() ? receiptShippingRegion : "-"%></strong></div>
                        <div class="col-12 mb-2"><span class="label-text">Delivery Address:</span><br><strong><%= receiptDeliveryAddress != null && !receiptDeliveryAddress.trim().isEmpty() ? receiptDeliveryAddress : "-"%></strong></div>
                    </div>

                    <h6 class="fw-bold mb-3"><i class="fas fa-shirt me-2"></i>Order Details</h6>
                    <div class="row small mb-3">
                        <div class="col-md-6 mb-2"><span class="label-text">Design:</span><br><strong><%= rs.getString("design_name") != null ? rs.getString("design_name") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Fit Preference:</span><br><strong><%= rs.getString("fit_preference") != null && !rs.getString("fit_preference").trim().isEmpty() ? rs.getString("fit_preference") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Top Fabric:</span><br><strong><%= rs.getString("shirt_fabric_name") != null ? rs.getString("shirt_fabric_name") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Bottom Fabric:</span><br><strong><%= rs.getString("skirt_fabric_name") != null && !rs.getString("skirt_fabric_name").trim().isEmpty() ? rs.getString("skirt_fabric_name") : "Same as top / Not selected"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Top Size:</span><br><strong><%= rs.getString("top_size") != null ? rs.getString("top_size") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Bottom Size:</span><br><strong><%= rs.getString("bottom_size") != null ? rs.getString("bottom_size") : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Height:</span><br><strong><%= rs.getObject("height_cm") != null ? rs.getDouble("height_cm") + " cm" : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Weight:</span><br><strong><%= rs.getObject("weight_kg") != null ? rs.getDouble("weight_kg") + " kg" : "-"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Decoration:</span><br><strong><%= rs.getString("decoration_name") != null && !rs.getString("decoration_name").trim().isEmpty() ? rs.getString("decoration_name") : "No Decoration"%></strong></div>
                        <div class="col-md-6 mb-2"><span class="label-text">Decoration Placement:</span><br><strong><%= rs.getString("decoration_area") != null && !rs.getString("decoration_area").trim().isEmpty() ? rs.getString("decoration_area") : "-"%></strong></div>
                        <div class="col-md-12 mb-2"><span class="label-text">Decoration Notes:</span><br><strong><%= rs.getString("decoration_notes") != null && !rs.getString("decoration_notes").trim().isEmpty() ? rs.getString("decoration_notes") : "-"%></strong></div>
                        <div class="col-12 mb-2"><span class="label-text">Special Request:</span><br><strong><%= rs.getString("special_request") != null && !rs.getString("special_request").trim().isEmpty() ? rs.getString("special_request") : "-"%></strong></div>
                    </div>

                    <h6 class="fw-bold mb-3"><i class="fas fa-credit-card me-2"></i>Payment Details</h6>
                    <div class="small mb-3">
                        <div class="d-flex justify-content-between mb-1"><span>Sewing Cost</span><strong>RM <%= String.format("%.2f", basePrice)%></strong></div>
                        <div class="d-flex justify-content-between mb-1"><span>Material Cost</span><strong>RM <%= String.format("%.2f", materialCost)%></strong></div>
                        <div class="d-flex justify-content-between mb-1"><span>Decoration Cost</span><strong>RM <%= String.format("%.2f", decorationPrice)%></strong></div>
                        <div class="d-flex justify-content-between mb-1"><span>Shipping Fee</span><strong>RM <%= String.format("%.2f", postage)%></strong></div>

                        <div class="receipt-line"></div>

                        <div class="d-flex justify-content-between align-items-center">
                            <span class="fw-bold">Grand Total</span>
                            <h4 class="mb-0" style="color:#043927;">RM <%= String.format("%.2f", grandTotal)%></h4>
                        </div>

                        <div class="mt-3"><span class="label-text">Payment Method:</span> <strong><%= rs.getString("payment_method") != null ? rs.getString("payment_method") : "-"%></strong></div>
                        <div><span class="label-text">Payment Reference:</span> <strong><%= rs.getString("payment_ref") != null ? rs.getString("payment_ref") : "-"%></strong></div>
                        <% if (rs.getString("tracking_number") != null && !rs.getString("tracking_number").trim().isEmpty()) { %>
                        <div class="mt-2"><span class="label-text">Courier:</span> <strong><%= rs.getString("courier_name") != null && !rs.getString("courier_name").trim().isEmpty() ? rs.getString("courier_name") : "-"%></strong></div>
                        <div><span class="label-text">Tracking Number:</span> <strong><%= rs.getString("tracking_number")%></strong></div>
                        <div class="small text-muted">Please use this tracking number to check your parcel status with the courier.</div>
                        <% } %>
                    </div>

                    <div class="receipt-line"></div>

                    <div class="d-flex gap-2 no-print">
                        <button onclick="window.print()" class="btn btn-dark">
                            <i class="fas fa-print me-1"></i> Print Receipt
                        </button>

                        <% if ("tailor".equals(currentUserRole)) { %>
                            <a href="tailor-dashboard.jsp?section=tasks" class="btn btn-outline-secondary">
                                <i class="fas fa-arrow-left me-1"></i> Back
                            </a>
                        <% } else { %>
                            <a href="order-history.jsp" class="btn btn-outline-secondary">
                                <i class="fas fa-arrow-left me-1"></i> Back
                            </a>
                        <% } %>
                    </div>

                    <%
                            }
                        } catch (Exception e) {
                    %>
                    <div class="alert alert-danger">Error: <%= e.getMessage()%></div>
                    <%
                        } finally {
                            try { if (rs != null) rs.close(); } catch (Exception ignore) {}
                            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
                            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
                        }

                        if (!found) {
                    %>
                    <div class="alert alert-warning mb-0">Receipt not found.</div>
                    <div class="mt-3 no-print">
                        <a href="order-history.jsp" class="btn btn-outline-secondary">Back</a>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>