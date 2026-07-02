<%--
    Document   : customer-dashboard
    Purpose    : Customer dashboard summary for FitStyle
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%
    if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("customer")) {
        response.sendRedirect("login.jsp?msg=Please login first!");
        return;
    }

    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");

    int activeOrders = 0;
    int pendingPayment = 0;
    int completedOrders = 0;
    int totalOrders = 0;
    double totalSpent = 0.00;
    Timestamp lastOrderDate = null;

    boolean hasLatestOrder = false;
    int latestOrderId = 0;
    String latestDesign = "-";
    String latestPaymentStatus = "pending";
    String latestProgressStatus = "pending";
    String latestProgressNote = "";
    String latestCourier = "";
    String latestTracking = "";
    double latestTotal = 0.00;
    Timestamp latestDate = null;

    boolean hasMeasurements = false;
    String topSize = "-";
    String bottomSize = "-";
    String fitPreference = "-";
    String heightCm = "-";
    String weightKg = "-";

    Connection dashConn = null;
    PreparedStatement dashPs = null;
    ResultSet dashRs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        dashConn = fitstyle.util.DBConnection.getConnection();

        String summarySql = "SELECT "
                + "COUNT(*) AS total_orders, "
                + "SUM(CASE WHEN (payment_status IS NULL OR payment_status <> 'paid') AND (order_status IS NULL OR order_status <> 'cancelled') THEN 1 ELSE 0 END) AS pending_payment, "
                + "SUM(CASE WHEN payment_status='paid' AND (progress_status IS NULL OR progress_status='' OR progress_status <> 'completed') THEN 1 ELSE 0 END) AS active_orders, "
                + "SUM(CASE WHEN payment_status='paid' AND progress_status='completed' THEN 1 ELSE 0 END) AS completed_orders, "
                + "SUM(CASE WHEN payment_status='paid' THEN total_price ELSE 0 END) AS total_spent, "
                + "MAX(order_date) AS last_order_date "
                + "FROM orders WHERE customer_id=?";
        dashPs = dashConn.prepareStatement(summarySql);
        dashPs.setInt(1, userId);
        dashRs = dashPs.executeQuery();
        if (dashRs.next()) {
            totalOrders = dashRs.getInt("total_orders");
            pendingPayment = dashRs.getInt("pending_payment");
            activeOrders = dashRs.getInt("active_orders");
            completedOrders = dashRs.getInt("completed_orders");
            totalSpent = dashRs.getDouble("total_spent");
            lastOrderDate = dashRs.getTimestamp("last_order_date");
        }
        dashRs.close();
        dashPs.close();

        String latestSql = "SELECT o.order_id, o.order_date, o.total_price, o.payment_status, o.progress_status, o.progress_note, "
                + "o.courier_name, o.tracking_number, d.design_name "
                + "FROM orders o LEFT JOIN designs d ON o.design_id=d.design_id "
                + "WHERE o.customer_id=? ORDER BY o.order_id DESC LIMIT 1";
        dashPs = dashConn.prepareStatement(latestSql);
        dashPs.setInt(1, userId);
        dashRs = dashPs.executeQuery();
        if (dashRs.next()) {
            hasLatestOrder = true;
            latestOrderId = dashRs.getInt("order_id");
            latestDesign = dashRs.getString("design_name") != null ? dashRs.getString("design_name") : "Custom Outfit";
            latestPaymentStatus = dashRs.getString("payment_status") != null ? dashRs.getString("payment_status") : "pending";
            latestProgressStatus = dashRs.getString("progress_status") != null && !dashRs.getString("progress_status").trim().isEmpty() ? dashRs.getString("progress_status") : "pending";
            latestProgressNote = dashRs.getString("progress_note") != null ? dashRs.getString("progress_note") : "";
            latestCourier = dashRs.getString("courier_name") != null ? dashRs.getString("courier_name") : "";
            latestTracking = dashRs.getString("tracking_number") != null ? dashRs.getString("tracking_number") : "";
            latestTotal = dashRs.getDouble("total_price");
            latestDate = dashRs.getTimestamp("order_date");
        }
        dashRs.close();
        dashPs.close();

        String measurementSql = "SELECT top_size, bottom_size, fit_preference, height_cm, weight_kg "
                + "FROM orders WHERE customer_id=? ORDER BY order_id DESC LIMIT 1";
        dashPs = dashConn.prepareStatement(measurementSql);
        dashPs.setInt(1, userId);
        dashRs = dashPs.executeQuery();
        if (dashRs.next()) {
            hasMeasurements = true;
            topSize = dashRs.getString("top_size") != null && !dashRs.getString("top_size").trim().isEmpty() ? dashRs.getString("top_size") : "-";
            bottomSize = dashRs.getString("bottom_size") != null && !dashRs.getString("bottom_size").trim().isEmpty() ? dashRs.getString("bottom_size") : "-";
            fitPreference = dashRs.getString("fit_preference") != null && !dashRs.getString("fit_preference").trim().isEmpty() ? dashRs.getString("fit_preference") : "-";
            heightCm = dashRs.getObject("height_cm") != null ? String.format("%.1f cm", dashRs.getDouble("height_cm")) : "-";
            weightKg = dashRs.getObject("weight_kg") != null ? String.format("%.1f kg", dashRs.getDouble("weight_kg")) : "-";
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try { if (dashRs != null) dashRs.close(); } catch (Exception ignore) {}
        try { if (dashPs != null) dashPs.close(); } catch (Exception ignore) {}
        try { if (dashConn != null) dashConn.close(); } catch (Exception ignore) {}
    }

    boolean latestPaid = "paid".equalsIgnoreCase(latestPaymentStatus);
    boolean latestCancelled = "cancelled".equalsIgnoreCase(latestPaymentStatus);
    int progressLevel = 0;
    if (latestPaid) {
        progressLevel = 1;
        if ("cutting".equalsIgnoreCase(latestProgressStatus)) progressLevel = 2;
        if ("sewing".equalsIgnoreCase(latestProgressStatus)) progressLevel = 3;
        if ("fitting".equalsIgnoreCase(latestProgressStatus)) progressLevel = 4;
        if ("completed".equalsIgnoreCase(latestProgressStatus)) progressLevel = 5;
    }

    String latestBadgeClass = "bg-warning text-dark";
    String latestBadgeText = "UNPAID";
    if (latestCancelled) {
        latestBadgeClass = "bg-danger";
        latestBadgeText = "PAYMENT CANCELLED";
    } else if (latestPaid && progressLevel == 5) {
        latestBadgeClass = "bg-success";
        latestBadgeText = "COMPLETED";
    } else if (latestPaid && progressLevel >= 2) {
        latestBadgeClass = "bg-info text-dark";
        latestBadgeText = "IN PROGRESS";
    } else if (latestPaid) {
        latestBadgeClass = "bg-primary";
        latestBadgeText = "PAID / WAITING TAILOR";
    }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Customer Dashboard | FitStyle</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            body {
                background-color: #f4f7f6;
                font-family: 'Poppins', sans-serif;
                color: var(--primary);
            }
            .sidebar {
                background-color: var(--primary);
                min-height: 100vh;
                color: white;
                padding-top: 20px;
            }
            .sidebar .nav-link {
                color: rgba(255,255,255,0.8);
                margin-bottom: 10px;
                transition: 0.3s;
                border-radius: 8px;
                padding: 10px 12px;
            }
            .sidebar .nav-link:hover,
            .sidebar .nav-link.active {
                color: var(--gold);
                background: rgba(212, 175, 55, 0.1);
            }
            .main-content { padding: 30px; }
            .stat-card, .content-card {
                background: white;
                border: none;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.06);
            }
            .stat-card {
                border-left: 5px solid var(--gold);
            }
            .btn-gold {
                background-color: var(--gold);
                color: var(--primary);
                border: none;
                font-weight: 600;
                transition: 0.3s;
            }
            .btn-gold:hover {
                background-color: #b8962d;
                color: white;
            }
            .progress-timeline {
                display: flex;
                align-items: center;
                gap: 7px;
                flex-wrap: wrap;
                margin-top: 12px;
            }
            .timeline-step {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 7px 11px;
                border-radius: 20px;
                font-size: 0.78rem;
                font-weight: 600;
                background: #e9ecef;
                color: #6c757d;
            }
            .timeline-step.done {
                background: #198754;
                color: white;
            }
            .timeline-step.active {
                background: var(--primary);
                color: var(--gold);
            }
            .timeline-arrow {
                color: #adb5bd;
                font-size: 0.75rem;
            }
            .info-box {
                background: #fff8e1;
                border-left: 4px solid var(--gold);
                border-radius: 12px;
                padding: 14px;
                color: #5c4a00;
            }
            .measurement-item {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 12px;
                height: 100%;
            }
            .label-small {
                font-size: 0.78rem;
                color: #6c757d;
            }
        </style>
    </head>
    <body>
        <jsp:include page="includes/navbar.jsp" />

        <div class="container-fluid">
            <div class="row">
                <nav class="col-md-2 d-none d-md-block sidebar text-center px-3">
                    <div class="position-sticky">
                        <i class="fas fa-user-circle fa-4x mb-3" style="color: var(--gold)"></i>
                        <h6 class="mb-4 text-white text-uppercase"><%= userName != null ? userName : "Customer"%></h6>

                        <ul class="nav flex-column text-start">
                            <li class="nav-item"><a class="nav-link active" href="customer-dashboard.jsp"><i class="fas fa-home me-2"></i> Dashboard</a></li>
                            <li class="nav-item"><a class="nav-link" href="order-history.jsp"><i class="fas fa-shopping-bag me-2"></i> My Orders</a></li>
                            <li class="nav-item"><a class="nav-link" href="measurement-record.jsp"><i class="fas fa-ruler-combined me-2"></i> Measurement Records</a></li>
                            <li class="nav-item"><a class="nav-link" href="profile.jsp"><i class="fas fa-id-card me-2"></i> My Profile</a></li>
                            <li class="nav-item"><a class="nav-link" href="auth-controller?action=logout"><i class="fas fa-sign-out-alt me-2"></i> Logout</a></li>
                        </ul>
                    </div>
                </nav>

                <main class="col-md-10 main-content">
                    <div class="d-flex justify-content-between align-items-center pt-3 pb-2 mb-4 border-bottom flex-wrap gap-2">
                        <div>
                            <h1 class="h2 mb-1">My Dashboard</h1>
                            <p class="text-muted mb-0">Welcome back, <strong><%= userName != null ? userName : "Customer"%></strong>.</p>
                        </div>
                        <a href="browse-designs.jsp" class="btn btn-gold"><i class="fas fa-plus me-2"></i> Order New Outfit</a>
                    </div>

                    <div class="row g-3 mb-4">
                        <div class="col-md-4">
                            <div class="card stat-card p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div><div class="text-muted small">Active Orders</div><h3 class="mb-0"><%= activeOrders%></h3></div>
                                    <i class="fas fa-scissors fa-2x text-muted opacity-50"></i>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="card stat-card p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div><div class="text-muted small">Pending Payment</div><h3 class="mb-0 text-warning"><%= pendingPayment%></h3></div>
                                    <i class="fas fa-credit-card fa-2x text-warning opacity-75"></i>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="card stat-card p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div><div class="text-muted small">Completed Orders</div><h3 class="mb-0 text-success"><%= completedOrders%></h3></div>
                                    <i class="fas fa-check-double fa-2x text-success opacity-75"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row g-4">
                        <div class="col-lg-8">
                            <div class="card content-card p-4 h-100">
                                <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
                                    <div>
                                        <h4 class="mb-1"><i class="fas fa-clock me-2"></i>Latest Order Progress</h4>
                                        <p class="text-muted small mb-0">Track your most recent order quickly from here.</p>
                                    </div>
                                    <% if (hasLatestOrder) { %>
                                    <a href="order-history.jsp" class="btn btn-outline-dark btn-sm">View My Orders</a>
                                    <% } %>
                                </div>

                                <% if (hasLatestOrder) { %>
                                <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
                                    <div>
                                        <h5 class="mb-1"><%= latestDesign%></h5>
                                        <div class="text-muted small">Order #FS-<%= latestOrderId%> | <%= latestDate != null ? latestDate : "-"%></div>
                                    </div>
                                    <div class="text-end">
                                        <div class="fw-bold">RM <%= String.format("%.2f", latestTotal)%></div>
                                        <span class="badge <%= latestBadgeClass %>"><%= latestBadgeText %></span>
                                    </div>
                                </div>

                                <div class="progress-timeline">
                                    <span class="timeline-step <%= progressLevel >= 1 ? "done" : ""%>"><i class="fas fa-check-circle"></i> Paid</span>
                                    <span class="timeline-arrow"><i class="fas fa-chevron-right"></i></span>
                                    <span class="timeline-step <%= progressLevel > 2 ? "done" : (progressLevel == 2 ? "active" : "")%>"><i class="fas fa-cut"></i> Cutting</span>
                                    <span class="timeline-arrow"><i class="fas fa-chevron-right"></i></span>
                                    <span class="timeline-step <%= progressLevel > 3 ? "done" : (progressLevel == 3 ? "active" : "")%>"><i class="fas fa-shirt"></i> Sewing</span>
                                    <span class="timeline-arrow"><i class="fas fa-chevron-right"></i></span>
                                    <span class="timeline-step <%= progressLevel > 4 ? "done" : (progressLevel == 4 ? "active" : "")%>"><i class="fas fa-ruler"></i> Fitting</span>
                                    <span class="timeline-arrow"><i class="fas fa-chevron-right"></i></span>
                                    <span class="timeline-step <%= progressLevel == 5 ? "done" : ""%>"><i class="fas fa-box-open"></i> Completed</span>
                                </div>

                                <% if (latestProgressNote != null && !latestProgressNote.trim().isEmpty()) { %>
                                <div class="info-box mt-3"><strong>Progress Note:</strong> <%= latestProgressNote%></div>
                                <% } %>

                                <div class="mt-3">
                                    <% if (latestTracking != null && !latestTracking.trim().isEmpty()) { %>
                                    <div class="alert alert-success mb-0">
                                        <i class="fas fa-truck me-1"></i>
                                        <strong>Tracking Available:</strong>
                                        <%= latestCourier != null && !latestCourier.trim().isEmpty() ? latestCourier + " - " : ""%><%= latestTracking%>
                                    </div>
                                    <% } else { %>
                                    <div class="alert alert-info mb-0">
                                        <i class="fas fa-info-circle me-1"></i>
                                        Tracking number will be available after your order is completed by the tailor.
                                    </div>
                                    <% } %>
                                </div>
                                <% } else { %>
                                <div class="text-center text-muted py-4">
                                    <i class="fas fa-shopping-bag fa-3x mb-3 opacity-50"></i>
                                    <h5>No orders yet</h5>
                                    <p class="mb-3">Start your first custom outfit order today.</p>
                                    <a href="browse-designs.jsp" class="btn btn-gold">Browse Designs</a>
                                </div>
                                <% } %>
                            </div>
                        </div>

                        <div class="col-lg-4">
                            <div class="card content-card p-4 h-100">
                                <h4 class="mb-3"><i class="fas fa-chart-pie me-2"></i>Order Summary</h4>
                                <div class="d-flex justify-content-between border-bottom py-2"><span>Total Orders Made</span><strong><%= totalOrders%></strong></div>
                                <div class="d-flex justify-content-between border-bottom py-2"><span>Total Amount Spent</span><strong>RM <%= String.format("%.2f", totalSpent)%></strong></div>
                                <div class="d-flex justify-content-between py-2"><span>Last Order Date</span><strong><%= lastOrderDate != null ? lastOrderDate.toString().substring(0, 10) : "-"%></strong></div>
                            </div>
                        </div>
                    </div>

                    <div class="row g-4 mt-1">
                        <div class="col-lg-8">
                            <div class="card content-card p-4">
                                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                                    <h4 class="mb-0"><i class="fas fa-ruler-combined me-2"></i>Latest Saved Measurements</h4>
                                    <a href="measurement-record.jsp" class="btn btn-outline-dark btn-sm">View Records</a>
                                </div>

                                <% if (hasMeasurements) { %>
                                <div class="row g-3">
                                    <div class="col-md-4"><div class="measurement-item"><div class="label-small">Top Size</div><strong><%= topSize%></strong></div></div>
                                    <div class="col-md-4"><div class="measurement-item"><div class="label-small">Bottom Size</div><strong><%= bottomSize%></strong></div></div>
                                    <div class="col-md-4"><div class="measurement-item"><div class="label-small">Fit Preference</div><strong><%= fitPreference%></strong></div></div>
                                    <div class="col-md-6"><div class="measurement-item"><div class="label-small">Height</div><strong><%= heightCm%></strong></div></div>
                                    <div class="col-md-6"><div class="measurement-item"><div class="label-small">Weight</div><strong><%= weightKg%></strong></div></div>
                                </div>
                                <% } else { %>
                                <p class="text-muted mb-0">No measurement record yet. Your measurements will appear here after you place an order.</p>
                                <% } %>
                            </div>
                        </div>

                        <div class="col-lg-4">
                            <div class="card content-card p-4">
                                <h4 class="mb-3"><i class="fas fa-bullhorn me-2"></i>Announcement</h4>
                                <div class="info-box">
                                    You can track order progress from the My Orders page. Courier and tracking number will be shown after the tailor marks your order as completed.
                                </div>
                                <a href="order-history.jsp" class="btn btn-gold w-100 mt-3">Go to My Orders</a>
                            </div>
                        </div>
                    </div>
                </main>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
