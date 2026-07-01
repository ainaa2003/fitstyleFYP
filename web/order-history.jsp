<%-- 
    Document   : order-history
    Updated    : Customer order history with payment status, progress timeline, receipt and safe cancel before payment
--%>

<%@page import="java.sql.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Order History | FitStyle</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            body {
                background-color: #f8f9fa;
                font-family: 'Poppins', sans-serif;
                color: #043927;
            }

            .table-card {
                border-radius: 15px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                overflow: hidden;
                border: none;
            }

            .thead-custom {
                background-color: #043927;
                color: #D4AF37;
            }

            .status-badge {
                padding: 6px 12px;
                border-radius: 20px;
                font-size: 0.72rem;
                font-weight: bold;
                text-transform: uppercase;
                display: inline-block;
            }

            .progress-timeline {
                display: flex;
                align-items: center;
                gap: 6px;
                flex-wrap: wrap;
                margin-top: 8px;
            }

            .timeline-step {
                display: inline-flex;
                align-items: center;
                gap: 5px;
                padding: 5px 9px;
                border-radius: 20px;
                font-size: 0.72rem;
                font-weight: 600;
                background: #e9ecef;
                color: #6c757d;
            }

            .timeline-step.active {
                background: #043927;
                color: #D4AF37;
            }

            .timeline-step.done {
                background: #198754;
                color: white;
            }

            .timeline-arrow {
                color: #adb5bd;
                font-size: 0.7rem;
            }

            .order-note {
                background: #fff8e1;
                border-left: 4px solid #D4AF37;
                padding: 8px 10px;
                border-radius: 8px;
                margin-top: 8px;
                font-size: 0.82rem;
                color: #5c4a00;
            }

            .btn-action {
                margin: 2px;
                white-space: nowrap;
            }

            .bulk-pay-box {
                background: #fff8e1;
                border: 1px solid #f1d36b;
                border-radius: 12px;
                padding: 12px 15px;
                margin-bottom: 15px;
            }

            .select-pay-col {
                width: 70px;
                text-align: center;
            }

            .sidebar {
                background-color: var(--primary);
                min-height: 100vh;
                color: white;
                padding-top: 20px;
            }
            .sidebar .nav-link {
                color: rgba(255,255,255,0.8) !important;
                margin-bottom: 10px;
                transition: 0.3s;
                border-radius: 8px;
                padding: 10px 12px;
                text-transform: none;
            }
            .sidebar .nav-link:hover,
            .sidebar .nav-link.active {
                color: var(--gold) !important;
                background: rgba(212, 175, 55, 0.1);
            }
            .main-content {
                padding: 30px;
            }
        </style>
    </head>

    <body>
        <%@include file="includes/navbar.jsp"%>

        <%
            Integer userId = (Integer) session.getAttribute("userId");
            String userName = (String) session.getAttribute("userName");

            if (userId == null) {
                response.sendRedirect("login.jsp");
                return;
            }

            if ("POST".equalsIgnoreCase(request.getMethod()) && "markReceived".equals(request.getParameter("action"))) {
                Connection receiveConn = null;
                PreparedStatement receivePs = null;
                try {
                    int receiveOrderId = Integer.parseInt(request.getParameter("orderId"));
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    receiveConn = fitstyle.util.DBConnection.getConnection();
                    receivePs = receiveConn.prepareStatement(
                            "UPDATE orders SET delivery_status='received', received_at=NOW(), order_status='received', "
                            + "progress_note='Customer has received the outfit. Review is now available.' "
                            + "WHERE order_id=? AND customer_id=? AND payment_status='paid' AND progress_status='completed' AND delivery_status='shipped'"
                    );
                    receivePs.setInt(1, receiveOrderId);
                    receivePs.setInt(2, userId);
                    receivePs.executeUpdate();
                    response.sendRedirect("order-history.jsp?msg=received");
                    return;
                } catch (Exception ex) {
                    response.sendRedirect("order-history.jsp?msg=receive_failed");
                    return;
                } finally {
                    try {
                        if (receivePs != null) {
                            receivePs.close();
                        }
                    } catch (Exception ignore) {
                    }
                    try {
                        if (receiveConn != null) {
                            receiveConn.close();
                        }
                    } catch (Exception ignore) {
                    }
                }
            }
        %>

        <div class="container-fluid">
            <div class="row">
                <nav class="col-md-2 d-none d-md-block sidebar text-center px-3">
                    <div class="position-sticky">
                        <i class="fas fa-user-circle fa-4x mb-3" style="color: var(--gold)"></i>
                        <h6 class="mb-4 text-white text-uppercase"><%= userName != null ? userName : "Customer"%></h6>

                        <ul class="nav flex-column text-start">
                            <li class="nav-item"><a class="nav-link" href="customer-dashboard.jsp"><i class="fas fa-home me-2"></i> Dashboard</a></li>
                            <li class="nav-item"><a class="nav-link active" href="order-history.jsp"><i class="fas fa-shopping-bag me-2"></i> My Orders</a></li>
                            <li class="nav-item"><a class="nav-link" href="measurement-record.jsp"><i class="fas fa-ruler-combined me-2"></i> Measurement Records</a></li>
                            <li class="nav-item"><a class="nav-link" href="profile.jsp"><i class="fas fa-id-card me-2"></i> My Profile</a></li>
                            <li class="nav-item"><a class="nav-link" href="auth-controller?action=logout"><i class="fas fa-sign-out-alt me-2"></i> Logout</a></li>
                        </ul>
                    </div>
                </nav>

                <main class="col-md-10 main-content">
                    <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
                        <div>
                            <h3 class="mb-1" style="color:#043927; font-weight:bold;">
                                <i class="fas fa-shopping-bag me-2"></i> My Orders
                            </h3>
                            <p class="text-muted small mb-0">Welcome back, <strong><%= userName != null ? userName : "Customer"%></strong></p>
                        </div>
                        <a href="browse-designs.jsp" class="btn btn-success btn-sm">
                            <i class="fas fa-plus me-1"></i> New Order
                        </a>
                    </div>

                    <%
                        String msg = request.getParameter("msg");
                        if (msg != null) {
                            String alertText = "";
                            String alertClass = "alert-info";

                            if ("cancelled".equals(msg)) {
                                alertText = "Order cancelled successfully.";
                                alertClass = "alert-success";
                            } else if ("cancel_not_allowed".equals(msg)) {
                                alertText = "This order cannot be cancelled because payment has already been made.";
                                alertClass = "alert-warning";
                            } else if ("updated".equals(msg)) {
                                alertText = "Order updated successfully.";
                                alertClass = "alert-success";
                            } else if ("deleted".equals(msg)) {
                                alertText = "Order removed successfully.";
                                alertClass = "alert-success";
                            } else if ("not_allowed".equals(msg)) {
                                alertText = "This order cannot be edited after payment.";
                                alertClass = "alert-warning";
                            } else if ("duplicate_prevented".equals(msg)) {
                                alertText = "Duplicate order submission was prevented.";
                                alertClass = "alert-warning";
                            } else if ("insufficient_stock".equals(msg)) {
                                alertText = "Selected fabric is no longer available or does not have enough stock. Please edit your order and choose another fabric before making payment.";
                                alertClass = "alert-danger";
                            } else if ("order_not_found".equals(msg)) {
                                alertText = "Order not found.";
                                alertClass = "alert-danger";
                            } else if ("missing_fabric_type".equals(msg)) {
                                alertText = "Fabric information is incomplete. Please edit your order before making payment.";
                                alertClass = "alert-danger";
                            } else if ("no_order_selected".equals(msg)) {
                                alertText = "Please select at least one unpaid order before making payment.";
                                alertClass = "alert-warning";
                            } else if ("review_added".equals(msg)) {
                                alertText = "Thank you. Your review has been submitted.";
                                alertClass = "alert-success";
                            } else if ("received".equals(msg)) {
                                alertText = "Order marked as received. You can now rate and review this order.";
                                alertClass = "alert-success";
                            } else if ("receive_failed".equals(msg)) {
                                alertText = "Unable to mark this order as received. Please make sure tracking has been provided by the tailor.";
                                alertClass = "alert-danger";
                            } else if ("review_exists".equals(msg)) {
                                alertText = "You already submitted a review for this order.";
                                alertClass = "alert-warning";
                            }

                            if (!alertText.isEmpty()) {
                    %>
                    <div class="alert <%= alertClass%> alert-dismissible fade show" role="alert">
                        <%= alertText%>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                    <%
                            }
                        }
                    %>

                    <%
                        String payment = request.getParameter("payment");
                        String paymentRef = request.getParameter("ref");
                        if ("success".equals(payment)) {
                    %>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        Payment successful. Selected order(s) have been confirmed.<% if (paymentRef != null && !paymentRef.trim().isEmpty()) {%> Reference: <strong><%= paymentRef%></strong><% } %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                    <% } else if ("failed".equals(payment)) { %>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        Payment failed. Please check your order and try again.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                    <% } %>

                    <form action="payment.jsp" method="POST" onsubmit="return validateBulkPayment();">
                        <div class="bulk-pay-box d-flex justify-content-between align-items-center flex-wrap gap-2">
                            <div>
                                <strong><i class="fas fa-cart-shopping me-1"></i> Pay Multiple Orders</strong>
                                <div class="small text-muted">Tick unpaid orders that you want to pay together. Postage will be counted once.</div>
                            </div>
                            <button type="submit" class="btn btn-warning fw-bold" style="background:#D4AF37; color:#043927; border:none;">
                                <i class="fas fa-credit-card me-1"></i> Pay Selected Orders
                            </button>
                        </div>

                        <div class="card table-card mt-4">
                            <div class="table-responsive">
                                <table class="table table-hover align-middle mb-0">
                                    <thead class="thead-custom">
                                        <tr>
                                            <th class="select-pay-col">Select</th>
                                            <th class="ps-4">Order</th>
                                            <th>Date</th>
                                            <th>Design & Fabric</th>
                                            <th>Total (RM)</th>
                                            <th>Payment</th>
                                            <th>Progress</th>
                                            <th class="text-center">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <%
                                            Connection conn = null;
                                            PreparedStatement ps = null;
                                            ResultSet rs = null;
                                            boolean adaData = false;

                                            try {
                                                Class.forName("com.mysql.cj.jdbc.Driver");
                                                conn = fitstyle.util.DBConnection.getConnection();

                                                String sql = "SELECT o.order_id, o.order_date, o.design_id, o.total_price, "
                                                        + "o.order_status, o.payment_status, o.payment_ref, o.progress_status, o.progress_note, o.progress_updated_at, "
                                                        + "o.courier_name, o.tracking_number, o.tracking_updated_at, o.delivery_status, o.shipped_at, o.received_at, "
                                                        + "o.shirt_fabric_name, o.skirt_fabric_name, o.top_size, o.bottom_size, o.fit_preference, "
                                            + "o.decoration_name, o.decoration_area, o.decoration_notes, COALESCE(o.decoration_price,0) AS decoration_price, "
                                                        + "d.design_name, "
                                                        + "(SELECT COUNT(*) FROM customer_reviews cr WHERE cr.order_id=o.order_id) AS review_count "
                                                        + "FROM orders o LEFT JOIN designs d ON o.design_id=d.design_id "
                                                        + "WHERE o.customer_id=? ORDER BY o.order_id DESC";

                                                ps = conn.prepareStatement(sql);
                                                ps.setInt(1, userId);
                                                rs = ps.executeQuery();

                                                while (rs.next()) {
                                                    adaData = true;

                                                    int orderId = rs.getInt("order_id");
                                                    String orderStatus = rs.getString("order_status");
                                                    String paymentStatus = rs.getString("payment_status");
                                                    String progressStatus = rs.getString("progress_status");
                                                    String progressNote = rs.getString("progress_note");
                                                    String courierName = rs.getString("courier_name");
                                                    String trackingNumber = rs.getString("tracking_number");
                                                    String deliveryStatus = rs.getString("delivery_status");
                                                    if (deliveryStatus == null || deliveryStatus.trim().isEmpty()) {
                                                        deliveryStatus = "";
                                                    }

                                                    if (orderStatus == null || orderStatus.trim().isEmpty()) {
                                                        orderStatus = "waiting_for_payment";
                                                    }
                                                    if (paymentStatus == null || paymentStatus.trim().isEmpty()) {
                                                        paymentStatus = "pending";
                                                    }
                                                    if (progressStatus == null || progressStatus.trim().isEmpty()) {
                                                        progressStatus = "pending";
                                                    }

                                                    boolean isPaid = "paid".equalsIgnoreCase(paymentStatus);
                                                    boolean isCancelled = "cancelled".equalsIgnoreCase(orderStatus) || "cancelled".equalsIgnoreCase(paymentStatus);

                                                    int progressLevel = 0;
                                                    if (isPaid) {
                                                        progressLevel = 1;
                                                        if ("cutting".equalsIgnoreCase(progressStatus)) {
                                                            progressLevel = 2;
                                                        }
                                                        if ("sewing".equalsIgnoreCase(progressStatus)) {
                                                            progressLevel = 3;
                                                        }
                                                        if ("fitting".equalsIgnoreCase(progressStatus)) {
                                                            progressLevel = 4;
                                                        }
                                                        if ("completed".equalsIgnoreCase(progressStatus)) {
                                                            progressLevel = 5;
                                                        }
                                                    }

                                                    boolean isCompleted = isPaid && progressLevel == 5;
                                                    boolean isShipped = isCompleted && "shipped".equalsIgnoreCase(deliveryStatus);
                                                    boolean isReceived = isCompleted && "received".equalsIgnoreCase(deliveryStatus);
                                                    boolean isReadyToShip = isCompleted && !isShipped && !isReceived;
                                                    boolean isInProgress = isPaid && progressLevel >= 2 && progressLevel < 5;

                                                    String paymentBadge = "bg-warning text-dark";
                                                    String paymentText = "UNPAID";
                                                    String progressMessage = "Unpaid - please complete payment to confirm this order.";

                                                    if (isCancelled) {
                                                        paymentBadge = "bg-danger text-white";
                                                        paymentText = "PAYMENT CANCELLED";
                                                        progressMessage = "Payment cancelled / order cancelled. Tailor will not process this order.";
                                                    } else if (isReceived) {
                                                        paymentBadge = "bg-success text-white";
                                                        paymentText = "RECEIVED";
                                                        progressMessage = "Order received. You may rate and review this order.";
                                                    } else if (isShipped) {
                                                        paymentBadge = "bg-primary text-white";
                                                        paymentText = "SHIPPED";
                                                        progressMessage = "Order has been posted. Please mark received after you get the parcel.";
                                                    } else if (isReadyToShip) {
                                                        paymentBadge = "bg-warning text-dark";
                                                        paymentText = "READY TO SHIP";
                                                        progressMessage = "Tailor has completed the outfit. Waiting for tracking details.";
                                                    } else if (isInProgress) {
                                                        paymentBadge = "bg-info text-dark";
                                                        paymentText = "IN PROGRESS";
                                                        progressMessage = "Tailor is processing this order.";
                                                    } else if (isPaid) {
                                                        paymentBadge = "bg-primary text-white";
                                                        paymentText = "PAID / WAITING TAILOR";
                                                        progressMessage = "Payment received. Waiting for tailor to start sewing task.";
                                                    }
                                        %>

                                        <tr>
                                            <td class="select-pay-col">
                                                <% if (!isPaid && !isCancelled) {%>
                                                <input type="checkbox" name="orderIds" value="<%= orderId%>" class="form-check-input order-pay-check">
                                                <% } else { %>
                                                <span class="text-muted">-</span>
                                                <% }%>
                                            </td>
                                            <td class="ps-4 fw-bold">#FS-<%= orderId%></td>
                                            <td class="small"><%= rs.getTimestamp("order_date")%></td>

                                            <td>
                                                <div class="fw-bold"><%= rs.getString("design_name") != null ? rs.getString("design_name") : "Design #" + rs.getInt("design_id")%></div>
                                                <div class="text-muted small">
                                                    <i class="fas fa-shirt me-1"></i>
                                                    Top: <%= rs.getString("shirt_fabric_name") != null ? rs.getString("shirt_fabric_name") : "-"%>
                                                </div>
                                                <div class="text-muted small">
                                                    Bottom: <%= rs.getString("skirt_fabric_name") != null && !rs.getString("skirt_fabric_name").trim().isEmpty() ? rs.getString("skirt_fabric_name") : "Same as top / Not selected"%>
                                                </div>
                                                <div class="text-muted small">
                                                    Size: Top <%= rs.getString("top_size") != null && !rs.getString("top_size").trim().isEmpty() ? rs.getString("top_size") : "-"%>,
                                                    Bottom <%= rs.getString("bottom_size") != null && !rs.getString("bottom_size").trim().isEmpty() ? rs.getString("bottom_size") : "-"%>
                                                </div>
                                            </td>

                                            <td class="fw-bold text-success">
                                                <%= String.format("%.2f", rs.getDouble("total_price"))%>
                                            </td>

                                            <td>
                                                <span class="status-badge <%= paymentBadge%>"><%= paymentText%></span>
                                                <% if (isPaid && rs.getString("payment_ref") != null) {%>
                                                <div class="small text-muted mt-1">Ref: <%= rs.getString("payment_ref")%></div>
                                                <% } %>
                                            </td>

                                            <td style="min-width: 340px;">
                                                <% if (isCancelled) { %>
                                                <span class="status-badge bg-danger text-white">Cancelled</span>
                                                <% } else if (!isPaid) {%>
                                                <div class="small text-muted"><%= progressMessage%></div>
                                                <% } else {%>
                                                <div class="progress-timeline">
                                                    <span class="timeline-step <%= progressLevel >= 1 ? "done" : ""%>"><i class="fas fa-credit-card"></i> Paid</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= progressLevel > 2 ? "done" : (progressLevel == 2 ? "active" : "")%>"><i class="fas fa-scissors"></i> Cutting</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= progressLevel > 3 ? "done" : (progressLevel == 3 ? "active" : "")%>"><i class="fas fa-shirt"></i> Sewing</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= progressLevel > 4 ? "done" : (progressLevel == 4 ? "active" : "")%>"><i class="fas fa-ruler"></i> Fitting</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= progressLevel == 5 ? "done" : ""%>"><i class="fas fa-check"></i> Completed</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= isShipped || isReceived ? "done" : ""%>"><i class="fas fa-truck"></i> Posted</span>
                                                    <span class="timeline-arrow">›</span>
                                                    <span class="timeline-step <%= isReceived ? "done" : ""%>"><i class="fas fa-box-open"></i> Received</span>
                                                </div>
                                                <% if (progressNote != null && !progressNote.trim().isEmpty()) {%>
                                                <div class="order-note"><i class="fas fa-note-sticky me-1"></i><%= progressNote%></div>
                                                    <% } %>
                                                    <% if (rs.getTimestamp("progress_updated_at") != null) {%>
                                                <div class="small text-muted mt-1">Last updated: <%= rs.getTimestamp("progress_updated_at")%></div>
                                                <div class="small text-muted">Estimated completion: 7 days after progress update</div>
                                                <% } %>
                                                <% if (trackingNumber != null && !trackingNumber.trim().isEmpty()) {%>
                                                <div class="order-note">
                                                    <i class="fas fa-truck-fast me-1"></i>
                                                    <strong>Delivery Tracking:</strong>
                                                    <%= courierName != null && !courierName.trim().isEmpty() ? courierName + " - " : ""%><%= trackingNumber%>
                                                    <div class="small mt-1">Please use this tracking number to check your parcel status with the courier.</div>
                                                    <% if (rs.getTimestamp("tracking_updated_at") != null) {%>
                                                    <div class="small text-muted">Tracking updated: <%= rs.getTimestamp("tracking_updated_at")%></div>
                                                    <% } %>
                                                    <% if (rs.getTimestamp("shipped_at") != null) {%>
                                                    <div class="small text-muted">Posted at: <%= rs.getTimestamp("shipped_at")%></div>
                                                    <% } %>
                                                    <% if (rs.getTimestamp("received_at") != null) {%>
                                                    <div class="small text-muted">Received at: <%= rs.getTimestamp("received_at")%></div>
                                                    <% } %>
                                                </div>
                                                <% } %>
                                                <% } %>
                                            </td>

                                            <td class="text-center">
                                                <% if (!isPaid && !isCancelled) {%>
                                                <a href="order-form.jsp?editOrderId=<%= orderId%>" class="btn btn-sm btn-warning btn-action">
                                                    <i class="fas fa-pen"></i> Edit
                                                </a>
                                                <a href="payment.jsp?id=<%= orderId%>" class="btn btn-sm btn-primary btn-action">
                                                    <i class="fas fa-credit-card"></i> Pay Now
                                                </a>
                                                <a href="OrderController?action=cancel&id=<%= orderId%>" class="btn btn-sm btn-danger btn-action"
                                                   onclick="return confirm('Cancel this order? This is only allowed before payment.')">
                                                    <i class="fas fa-ban"></i> Cancel
                                                </a>
                                                <% } else if (isPaid) {%>
                                                <a href="receipt.jsp?id=<%= orderId%>" class="btn btn-sm btn-outline-dark btn-action">
                                                    <i class="fas fa-file-invoice"></i> Receipt
                                                </a>
                                                <% if (isShipped) {%>
                                                <button type="button"
                                                        class="btn btn-sm btn-success btn-action"
                                                        onclick="markReceived(<%= orderId%>)">
                                                    <i class="fas fa-box-open"></i> Received
                                                </button>
                                                <% } %>
                                                <% if (isReceived) { %>
                                                <% if (rs.getInt("review_count") > 0) { %>
                                                <span class="badge bg-success d-inline-block mt-1">Reviewed</span>
                                                <% } else {%>
                                                <a href="review.jsp?orderId=<%= orderId%>" class="btn btn-sm btn-success btn-action">
                                                    <i class="fas fa-star"></i> Rate & Review
                                                </a>
                                                <% } %>
                                                <% } else if (isReadyToShip) { %>
                                                <span class="badge bg-warning text-dark d-inline-block mt-1">Waiting Tracking</span>
                                                <% } %>
                                                <% } else { %>
                                                <span class="badge bg-danger">Cancelled</span>
                                                <% } %>
                                            </td>
                                        </tr>

                                        <%
                                            }

                                            if (!adaData) {
                                        %>
                                        <tr>
                                            <td colspan="8" class="text-center py-5 text-muted">
                                                <i class="fas fa-box-open fa-3x mb-3"></i><br>
                                                No orders found.
                                            </td>
                                        </tr>
                                        <%
                                            }
                                        } catch (Exception e) {
                                        %>
                                        <tr>
                                            <td colspan="8" class="text-danger text-center py-4">
                                                Error: <%= e.getMessage()%>
                                            </td>
                                        </tr>
                                        <%
                                            } finally {
                                                try {
                                                    if (rs != null) {
                                                        rs.close();
                                                    }
                                                } catch (Exception ignore) {
                                                }
                                                try {
                                                    if (ps != null) {
                                                        ps.close();
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
                                        %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </form>
                </main>
            </div>
        </div>

        <script>
            function validateBulkPayment() {
                const checked = document.querySelectorAll('.order-pay-check:checked');
                if (checked.length === 0) {
                    alert('Please tick at least one unpaid order to pay.');
                    return false;
                }
                return true;
            }

            function markReceived(orderId) {
                if (confirm("Confirm that you have received this outfit?")) {
                    const form = document.createElement("form");
                    form.method = "POST";
                    form.action = "order-history.jsp";

                    const actionInput = document.createElement("input");
                    actionInput.type = "hidden";
                    actionInput.name = "action";
                    actionInput.value = "markReceived";

                    const orderInput = document.createElement("input");
                    orderInput.type = "hidden";
                    orderInput.name = "orderId";
                    orderInput.value = orderId;

                    form.appendChild(actionInput);
                    form.appendChild(orderInput);
                    document.body.appendChild(form);
                    form.submit();
                }
            }
        </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
