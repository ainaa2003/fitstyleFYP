<%-- 
    Document   : tailor-dashboard
    Created on : Jan 19, 2026, 12:59:04 AM
    Author     : Acer
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="fitstyle.dao.DesignDAO"%>
<%@page import="fitstyle.model.Design"%>
<%@page import="fitstyle.model.Material"%>
<%@page import="java.util.List"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="java.sql.*"%>
<%
    if (session.getAttribute("userRole") == null || !session.getAttribute("userRole").equals("tailor")) {
        response.sendRedirect("login.jsp?msg=Access denied!");
        return;
    }

    String section = request.getParameter("section");
    if (section == null || section.trim().isEmpty()) {
        section = "dashboard";
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "updateProgress".equals(request.getParameter("action"))) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = fitstyle.util.DBConnection.getConnection();

            String progressStatus = request.getParameter("progressStatus");
            String progressNote = request.getParameter("progressNote");

            String autoNote = "";

            if ("pending".equals(progressStatus)) {
                autoNote = "Payment received. Waiting for tailor to start sewing task.";
            } else if ("cutting".equals(progressStatus)) {
                autoNote = "Your fabric is currently being cut according to the selected design and size.";
            } else if ("sewing".equals(progressStatus)) {
                autoNote = "Your outfit is currently in the sewing process.";
            } else if ("fitting".equals(progressStatus)) {
                autoNote = "Your outfit is almost ready and is now in the fitting/checking stage.";
            } else if ("completed".equals(progressStatus)) {
                autoNote = "Your order has been completed by the tailor. Waiting for delivery tracking details.";
            } else {
                autoNote = "Your order progress has been updated.";
            }

            if (progressNote == null || progressNote.trim().isEmpty()) {
                progressNote = autoNote;
            }

            String sql = "UPDATE orders SET progress_status=?, progress_note=?, progress_updated_at=NOW(), "
                    + "order_status=CASE WHEN ?='completed' THEN 'ready_to_ship' ELSE 'in_progress' END, "
                    + "delivery_status=CASE WHEN ?='completed' AND (delivery_status IS NULL OR delivery_status='') THEN 'ready_to_ship' ELSE delivery_status END "
                    + "WHERE order_id=? AND payment_status='paid'";
            ps = conn.prepareStatement(sql);
            ps.setString(1, progressStatus);
            ps.setString(2, progressNote.trim());
            ps.setString(3, progressStatus);
            ps.setString(4, progressStatus);
            ps.setInt(5, Integer.parseInt(request.getParameter("orderId")));
            ps.executeUpdate();

            if ("completed".equals(progressStatus)) {
                response.sendRedirect("tailor-dashboard.jsp?section=shipping&msg=Order completed. Please add courier and tracking number.");
            } else {
                response.sendRedirect("tailor-dashboard.jsp?section=tasks&msg=Progress updated successfully");
            }
            return;
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("tailor-dashboard.jsp?section=tasks&msg=Failed to update progress");
            return;
        } finally {
            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
        }
    }

    if ("POST".equalsIgnoreCase(request.getMethod()) && "updateShipping".equals(request.getParameter("action"))) {
        Connection conn = null;
        PreparedStatement ps = null;
        try {
            String courierName = request.getParameter("courierName");
            String trackingNumber = request.getParameter("trackingNumber");
            String orderIdParam = request.getParameter("orderId");

            if (courierName == null || courierName.trim().isEmpty() || trackingNumber == null || trackingNumber.trim().isEmpty()) {
                response.sendRedirect("tailor-dashboard.jsp?section=shipping&msg=Please fill in courier and tracking number");
                return;
            }

            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = fitstyle.util.DBConnection.getConnection();
            String sql = "UPDATE orders SET courier_name=?, tracking_number=?, tracking_updated_at=NOW(), "
                    + "delivery_status='shipped', shipped_at=NOW(), order_status='shipped', "
                    + "progress_note='Your order has been posted. Please check the tracking number and press Received after receiving the parcel.' "
                    + "WHERE order_id=? AND payment_status='paid' AND progress_status='completed'";
            ps = conn.prepareStatement(sql);
            ps.setString(1, courierName.trim());
            ps.setString(2, trackingNumber.trim());
            ps.setInt(3, Integer.parseInt(orderIdParam));
            ps.executeUpdate();

            response.sendRedirect("tailor-dashboard.jsp?section=shipping&msg=Tracking details saved successfully");
            return;
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("tailor-dashboard.jsp?section=shipping&msg=Failed to save tracking details");
            return;
        } finally {
            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
        }
    }

    DesignDAO dao = new DesignDAO();
    List<Design> designList = dao.getAllDesigns();
    List<Material> materialList = dao.getAllMaterials();
                        int totalOrders = 0;
                        int paidOrders = 0;
                        int pendingSewing = 0;
                        int completedOrders = 0;
                        double totalSales = 0.00;
                        double todaySales = 0.00;
                        double monthlySales = 0.00;

                        Connection summaryConn = null;
                        PreparedStatement summaryPs = null;
                        ResultSet summaryRs = null;

                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            summaryConn = fitstyle.util.DBConnection.getConnection();

                            String summarySql = "SELECT "
                                    + "SUM(CASE WHEN payment_status='paid' THEN 1 ELSE 0 END) AS total_orders, "
                                    + "SUM(CASE WHEN payment_status='paid' AND progress_status<>'completed' THEN 1 ELSE 0 END) AS paid_orders, "
                                    + "SUM(CASE WHEN payment_status='paid' AND (progress_status IS NULL OR progress_status='' OR progress_status='pending') THEN 1 ELSE 0 END) AS pending_sewing, "
                                    + "SUM(CASE WHEN payment_status='paid' AND progress_status='completed' THEN 1 ELSE 0 END) AS completed_orders, "
                                    + "SUM(CASE WHEN payment_status='paid' THEN COALESCE(total_price,0)+COALESCE(shipping_fee,0) ELSE 0 END) AS total_sales, "
                                    + "SUM(CASE WHEN payment_status='paid' AND DATE(order_date)=CURDATE() THEN COALESCE(total_price,0)+COALESCE(shipping_fee,0) ELSE 0 END) AS today_sales, "
                                    + "SUM(CASE WHEN payment_status='paid' AND YEAR(order_date)=YEAR(CURDATE()) AND MONTH(order_date)=MONTH(CURDATE()) THEN COALESCE(total_price,0)+COALESCE(shipping_fee,0) ELSE 0 END) AS monthly_sales "
                                    + "FROM orders";

                            summaryPs = summaryConn.prepareStatement(summarySql);
                            summaryRs = summaryPs.executeQuery();

                            if (summaryRs.next()) {
                                totalOrders = summaryRs.getInt("total_orders");
                                paidOrders = summaryRs.getInt("paid_orders");
                                pendingSewing = summaryRs.getInt("pending_sewing");
                                completedOrders = summaryRs.getInt("completed_orders");
                                totalSales = summaryRs.getDouble("total_sales");
                                todaySales = summaryRs.getDouble("today_sales");
                                monthlySales = summaryRs.getDouble("monthly_sales");
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        } finally {
                            try {
                                if (summaryRs != null) {
                                    summaryRs.close();
                                }
                            } catch (Exception ignore) {
                            }
                            try {
                                if (summaryPs != null) {
                                    summaryPs.close();
                                }
                            } catch (Exception ignore) {
                            }
                            try {
                                if (summaryConn != null) {
                                    summaryConn.close();
                                }
                            } catch (Exception ignore) {
                            }
                        }
%>
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Tailor Dashboard | FitStyle</title>
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

            .nav-link {
                color: rgba(255, 255, 255, 0.8);
                margin-bottom: 10px;
            }

            .nav-link:hover,
            .nav-link.active {
                color: var(--gold);
            }

            .card-custom {
                border: none;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0, 0, 0, 0.05);
            }

            .btn-emerald {
                background: var(--primary);
                color: var(--gold);
                border: none;
                font-weight: 600;
            }

            .btn-emerald:hover {
                background: var(--gold);
                color: var(--primary);
            }

            .table-img {
                width: 60px;
                height: 70px;
                object-fit: cover;
                border-radius: 8px;
            }

            .mini-stat {
                background: #ffffff;
                border-radius: 14px;
                padding: 18px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.05);
                height: 100%;
            }

            .mini-stat .label {
                color: #6c757d;
                font-size: 0.85rem;
            }

            .mini-stat .value {
                color: #043927;
                font-weight: 700;
                font-size: 1.35rem;
            }

        @media print { .sidebar, .navbar, .no-print, .btn { display:none !important; } main { width:100% !important; } .card { box-shadow:none !important; } }
        </style>
    </head>
    <body>

        <jsp:include page="includes/navbar.jsp" />

        <div class="container-fluid">
            <div class="row">
                <nav class="col-md-2 d-none d-md-block sidebar text-center">
                    <h5 class="my-4" style="color:var(--gold)">Tailor Menu</h5>
                    <ul class="nav flex-column text-start px-3">
                        <li class="nav-item"><a class="nav-link <%= "dashboard".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=dashboard"><i class="fas fa-home me-2"></i> Dashboard</a></li>
                        <li class="nav-item"><a class="nav-link <%= "design".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=design"><i class="fas fa-plus-circle me-2"></i> Add Design</a></li>
                        <li class="nav-item"><a class="nav-link <%= "material".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=material"><i class="fas fa-scroll me-2"></i> Manage Material</a></li>
                        <li class="nav-item"><a class="nav-link <%= "decoration".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=decoration"><i class="fas fa-wand-magic-sparkles me-2"></i> Manage Decoration</a></li>
                        <li class="nav-item"><a class="nav-link <%= "customers".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=customers"><i class="fas fa-users me-2"></i> Customer Management</a></li>
                        <li class="nav-item"><a class="nav-link <%= "tasks".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=tasks"><i class="fas fa-list me-2"></i> Sewing Tasks</a></li>
                        <li class="nav-item"><a class="nav-link <%= "shipping".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=shipping"><i class="fas fa-truck-fast me-2"></i> Delivery / Tracking</a></li>
                        <li class="nav-item"><a class="nav-link <%= "sales-report".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=sales-report"><i class="fas fa-chart-line me-2"></i> Sales Report</a></li>
                        <li class="nav-item"><a class="nav-link <%= "reviews".equals(section) ? "active" : ""%>" href="tailor-dashboard.jsp?section=reviews"><i class="fas fa-star me-2"></i> Reviews</a></li>
                    </ul>
                </nav>

                <main class="col-md-10 p-4">

                    <% if (request.getParameter("msg") != null) {%>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle me-2"></i> <%= request.getParameter("msg")%>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                    <% }%>

                    <% if ("dashboard".equals(section)) { %>

                    <div class="mb-4">
                        <h2>Business Dashboard</h2>
                        <p class="text-muted">
                            Welcome back! Here is an overview of your tailoring business.
                        </p>
                    </div>

                    <div class="row g-3 mb-4 dashboard-summary-row">
                        <div class="col-md-6 col-xl">
                            <div class="card card-custom p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <div class="text-muted small">Paid Orders</div>
                                        <h3 class="mb-0" style="color:#043927;"><%= totalOrders%></h3>
                                    </div>
                                    <i class="fas fa-receipt fa-2x" style="color:#D4AF37;"></i>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-xl">
                            <div class="card card-custom p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <div class="text-muted small">Orders In Progress</div>
                                        <h3 class="mb-0 text-success"><%= paidOrders%></h3>
                                    </div>
                                    <i class="fas fa-circle-check fa-2x text-success"></i>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-xl">
                            <div class="card card-custom p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <div class="text-muted small">Pending Sewing</div>
                                        <h3 class="mb-0 text-warning"><%= pendingSewing%></h3>
                                    </div>
                                    <i class="fas fa-scissors fa-2x text-warning"></i>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-xl">
                            <div class="card card-custom p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <div class="text-muted small">Completed</div>
                                        <h3 class="mb-0 text-primary"><%= completedOrders%></h3>
                                    </div>
                                    <i class="fas fa-box-open fa-2x text-primary"></i>
                                </div>
                            </div>
                        </div>

                        <div class="col-md-6 col-xl">
                            <div class="card card-custom p-3 h-100">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <div class="text-muted small">Total Sales</div>
                                        <h4 class="mb-0" style="color:#043927;">RM <%= String.format("%.2f", totalSales)%></h4>
                                    </div>
                                    <i class="fas fa-sack-dollar fa-2x" style="color:#D4AF37;"></i>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="row g-3 mb-4">
                        <div class="col-md-6">
                            <div class="mini-stat">
                                <div class="label"><i class="fas fa-calendar-day me-1"></i> Sales Today</div>
                                <div class="value">RM <%= String.format("%.2f", todaySales)%></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mini-stat">
                                <div class="label"><i class="fas fa-calendar-alt me-1"></i> Sales This Month</div>
                                <div class="value">RM <%= String.format("%.2f", monthlySales)%></div>
                            </div>
                        </div>
                    </div>

                    <div class="card card-custom p-4 mb-4">
                        <h5 class="mb-3" style="color:#043927;">
                            <i class="fas fa-clock me-2"></i> Recent Orders
                        </h5>
                        <div class="table-responsive">
                            <table class="table align-middle mb-0">
                                <thead>
                                    <tr>
                                        <th>Order ID</th>
                                        <th>Customer</th>
                                        <th>Progress</th>
                                        <th>Payment</th>
                                        <th>Total (RM)</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        Connection recentConn = null;
                                        PreparedStatement recentPs = null;
                                        ResultSet recentRs = null;
                                        boolean hasRecent = false;

                                        try {
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            recentConn = fitstyle.util.DBConnection.getConnection();

                                            String recentSql = "SELECT o.order_id, o.total_price, o.payment_status, o.progress_status, o.order_date, u.full_name "
                                                    + "FROM orders o JOIN users u ON o.customer_id=u.user_id "
                                                    + "WHERE o.payment_status='paid' AND (o.progress_status IS NULL OR o.progress_status <> 'completed') "
                                                    + "ORDER BY o.order_id DESC LIMIT 5";
                                            recentPs = recentConn.prepareStatement(recentSql);
                                            recentRs = recentPs.executeQuery();

                                            while (recentRs.next()) {
                                                hasRecent = true;
                                                String recentPayment = recentRs.getString("payment_status") != null ? recentRs.getString("payment_status") : "pending";
                                                String recentProgress = recentRs.getString("progress_status") != null ? recentRs.getString("progress_status") : "pending";
                                    %>
                                    <tr>
                                        <td class="fw-bold">#FS-<%= recentRs.getInt("order_id")%></td>
                                        <td><%= recentRs.getString("full_name")%></td>
                                        <td><span class="badge bg-info text-dark"><%= recentProgress.toUpperCase()%></span></td>
                                        <td>
                                            <% if ("paid".equalsIgnoreCase(recentPayment)) { %>
                                                <span class="badge bg-success">PAID</span>
                                            <% } else if ("cancelled".equalsIgnoreCase(recentPayment)) { %>
                                                <span class="badge bg-danger">CANCELLED</span>
                                            <% } else { %>
                                                <span class="badge bg-warning text-dark">PENDING</span>
                                            <% } %>
                                        </td>
                                        <td>RM <%= String.format("%.2f", recentRs.getDouble("total_price"))%></td>
                                        <td class="small text-muted"><%= recentRs.getTimestamp("order_date")%></td>
                                    </tr>
                                    <%
                                            }

                                            if (!hasRecent) {
                                    %>
                                    <tr>
                                        <td colspan="6" class="text-center text-muted py-3">No recent orders yet.</td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                    %>
                                    <tr>
                                        <td colspan="6" class="text-center text-danger py-3">Unable to load recent orders.</td>
                                    </tr>
                                    <%
                                        } finally {
                                            try { if (recentRs != null) recentRs.close(); } catch (Exception ignore) {}
                                            try { if (recentPs != null) recentPs.close(); } catch (Exception ignore) {}
                                            try { if (recentConn != null) recentConn.close(); } catch (Exception ignore) {}
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <% } else if ("customers".equals(section)) { %>
                    <%
                        String customerIdParam = request.getParameter("customerId");
                    %>

                    <div class="card card-custom p-4 mb-4">
                        <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                            <div>
                                <h5 class="mb-1" style="color:#043927;"><i class="fas fa-users me-2"></i> Customer Management</h5>
                                <p class="text-muted small mb-0">View registered customers with paid orders only and total paid spending.</p>
                            </div>
                            <% if (customerIdParam != null && !customerIdParam.trim().isEmpty()) { %>
                            <a href="tailor-dashboard.jsp?section=customers" class="btn btn-outline-secondary btn-sm">
                                <i class="fas fa-arrow-left me-1"></i> Back to Customer List
                            </a>
                            <% } %>
                        </div>

                        <% if (customerIdParam == null || customerIdParam.trim().isEmpty()) { %>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Customer</th>
                                        <th>Email</th>
                                        <th>Phone</th>
                                        <th>Paid Orders</th>
                                        <th>Total Spent (RM)</th>
                                        <th>Last Order</th>
                                        <th class="text-center">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        Connection custConn = null;
                                        PreparedStatement custPs = null;
                                        ResultSet custRs = null;
                                        boolean hasCustomer = false;

                                        try {
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            custConn = fitstyle.util.DBConnection.getConnection();

                                            String custSql = "SELECT u.user_id, u.full_name, u.email, u.phone, u.created_at, "
                                                    + "COUNT(o.order_id) AS total_orders, "
                                                    + "COUNT(o.order_id) AS paid_orders, "
                                                    + "SUM(COALESCE(o.total_price,0) + COALESCE(o.shipping_fee,0)) AS total_spent, "
                                                    + "MAX(o.order_date) AS last_order_date "
                                                    + "FROM users u "
                                                    + "LEFT JOIN orders o ON u.user_id=o.customer_id AND o.payment_status='paid' "
                                                    + "WHERE u.role='customer' "
                                                    + "GROUP BY u.user_id, u.full_name, u.email, u.phone, u.created_at "
                                                    + "ORDER BY u.created_at DESC";

                                            custPs = custConn.prepareStatement(custSql);
                                            custRs = custPs.executeQuery();

                                            while (custRs.next()) {
                                                hasCustomer = true;
                                    %>
                                    <tr>
                                        <td>
                                            <div class="fw-bold"><%= custRs.getString("full_name") != null ? custRs.getString("full_name") : "-"%></div>
                                            <div class="small text-muted">Joined: <%= custRs.getTimestamp("created_at") != null ? custRs.getTimestamp("created_at") : "-"%></div>
                                        </td>
                                        <td><%= custRs.getString("email") != null ? custRs.getString("email") : "-"%></td>
                                        <td><%= custRs.getString("phone") != null ? custRs.getString("phone") : "-"%></td>
                                        <td><span class="badge bg-success"><%= custRs.getInt("total_orders")%></span></td>
                                        <td class="fw-bold" style="color:#043927;">RM <%= String.format("%.2f", custRs.getDouble("total_spent"))%></td>
                                        <td class="small text-muted"><%= custRs.getTimestamp("last_order_date") != null ? custRs.getTimestamp("last_order_date") : "-"%></td>
                                        <td class="text-center">
                                            <a class="btn btn-emerald btn-sm" href="tailor-dashboard.jsp?section=customers&customerId=<%= custRs.getInt("user_id")%>">
                                                <i class="fas fa-eye me-1"></i> View Orders
                                            </a>
                                        </td>
                                    </tr>
                                    <%
                                            }

                                            if (!hasCustomer) {
                                    %>
                                    <tr>
                                        <td colspan="7" class="text-center text-muted py-4">No registered customers yet.</td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                    %>
                                    <tr>
                                        <td colspan="7" class="text-center text-danger py-4">Unable to load customers.</td>
                                    </tr>
                                    <%
                                        } finally {
                                            try { if (custRs != null) custRs.close(); } catch (Exception ignore) {}
                                            try { if (custPs != null) custPs.close(); } catch (Exception ignore) {}
                                            try { if (custConn != null) custConn.close(); } catch (Exception ignore) {}
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                        <% } else { %>
                        <%
                            int selectedCustomerId = 0;
                            try {
                                selectedCustomerId = Integer.parseInt(customerIdParam);
                            } catch (Exception ignore) {
                                selectedCustomerId = 0;
                            }

                            String selectedCustomerName = "-";
                            String selectedCustomerEmail = "-";
                            String selectedCustomerPhone = "-";
                            String selectedCustomerAddress = "-";
                            int selectedTotalOrders = 0;
                            int selectedPaidOrders = 0;
                            double selectedTotalSpent = 0.00;

                            Connection detailConn = null;
                            PreparedStatement detailPs = null;
                            ResultSet detailRs = null;

                            try {
                                Class.forName("com.mysql.cj.jdbc.Driver");
                                detailConn = fitstyle.util.DBConnection.getConnection();

                                String detailSql = "SELECT u.full_name, u.email, u.phone, u.address, "
                                        + "COUNT(o.order_id) AS total_orders, "
                                        + "COUNT(o.order_id) AS paid_orders, "
                                        + "SUM(COALESCE(o.total_price,0) + COALESCE(o.shipping_fee,0)) AS total_spent "
                                        + "FROM users u LEFT JOIN orders o ON u.user_id=o.customer_id AND o.payment_status='paid' "
                                        + "WHERE u.user_id=? AND u.role='customer' "
                                        + "GROUP BY u.user_id, u.full_name, u.email, u.phone, u.address";

                                detailPs = detailConn.prepareStatement(detailSql);
                                detailPs.setInt(1, selectedCustomerId);
                                detailRs = detailPs.executeQuery();

                                if (detailRs.next()) {
                                    selectedCustomerName = detailRs.getString("full_name") != null ? detailRs.getString("full_name") : "-";
                                    selectedCustomerEmail = detailRs.getString("email") != null ? detailRs.getString("email") : "-";
                                    selectedCustomerPhone = detailRs.getString("phone") != null ? detailRs.getString("phone") : "-";
                                    selectedCustomerAddress = detailRs.getString("address") != null ? detailRs.getString("address") : "-";
                                    selectedTotalOrders = detailRs.getInt("total_orders");
                                    selectedPaidOrders = detailRs.getInt("paid_orders");
                                    selectedTotalSpent = detailRs.getDouble("total_spent");
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                try { if (detailRs != null) detailRs.close(); } catch (Exception ignore) {}
                                try { if (detailPs != null) detailPs.close(); } catch (Exception ignore) {}
                                try { if (detailConn != null) detailConn.close(); } catch (Exception ignore) {}
                            }
                        %>

                        <div class="row g-3 mb-4">
                            <div class="col-md-8">
                                <div class="p-3 bg-light rounded h-100">
                                    <h6 class="fw-bold mb-2"><i class="fas fa-user me-1"></i> Customer Details</h6>
                                    <div class="small"><strong>Name:</strong> <%= selectedCustomerName%></div>
                                    <div class="small"><strong>Email:</strong> <%= selectedCustomerEmail%></div>
                                    <div class="small"><strong>Phone:</strong> <%= selectedCustomerPhone%></div>
                                    <div class="small"><strong>Address:</strong> <%= selectedCustomerAddress%></div>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <div class="p-3 bg-light rounded h-100">
                                    <h6 class="fw-bold mb-2"><i class="fas fa-chart-simple me-1"></i> Order Summary</h6>
                                    <div class="small"><strong>Paid Orders:</strong> <%= selectedTotalOrders%></div>
                                    <div class="small"><strong>Total Spent:</strong> RM <%= String.format("%.2f", selectedTotalSpent)%></div>
                                </div>
                            </div>
                        </div>

                        <h6 class="fw-bold mb-3"><i class="fas fa-receipt me-1"></i> Paid Customer Orders</h6>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Order ID</th>
                                        <th>Date</th>
                                        <th>Design</th>
                                        <th>Fabric</th>
                                        <th>Total (RM)</th>
                                        <th>Payment</th>
                                        <th>Progress</th>
                                        <th>Tracking</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        Connection orderConn = null;
                                        PreparedStatement orderPs = null;
                                        ResultSet orderRs = null;
                                        boolean hasCustomerOrders = false;

                                        try {
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            orderConn = fitstyle.util.DBConnection.getConnection();

                                            String orderSql = "SELECT o.order_id, o.order_date, o.total_price, o.payment_status, o.order_status, "
                                                    + "o.progress_status, o.courier_name, o.tracking_number, o.shirt_fabric_name, o.skirt_fabric_name, "
                                                    + "d.design_name "
                                                    + "FROM orders o LEFT JOIN designs d ON o.design_id=d.design_id "
                                                    + "WHERE o.customer_id=? AND o.payment_status='paid' "
                                                    + "ORDER BY o.order_id DESC";

                                            orderPs = orderConn.prepareStatement(orderSql);
                                            orderPs.setInt(1, selectedCustomerId);
                                            orderRs = orderPs.executeQuery();

                                            while (orderRs.next()) {
                                                hasCustomerOrders = true;
                                                String payStatus = orderRs.getString("payment_status") != null ? orderRs.getString("payment_status") : "pending";
                                                String progStatus = orderRs.getString("progress_status") != null && !orderRs.getString("progress_status").trim().isEmpty() ? orderRs.getString("progress_status") : "pending";
                                                String trackNo = orderRs.getString("tracking_number");
                                                String courier = orderRs.getString("courier_name");
                                    %>
                                    <tr>
                                        <td class="fw-bold">#FS-<%= orderRs.getInt("order_id")%></td>
                                        <td class="small text-muted"><%= orderRs.getTimestamp("order_date")%></td>
                                        <td><%= orderRs.getString("design_name") != null ? orderRs.getString("design_name") : "-"%></td>
                                        <td class="small">
                                            Top: <%= orderRs.getString("shirt_fabric_name") != null ? orderRs.getString("shirt_fabric_name") : "-"%><br>
                                            Bottom: <%= orderRs.getString("skirt_fabric_name") != null && !orderRs.getString("skirt_fabric_name").trim().isEmpty() ? orderRs.getString("skirt_fabric_name") : "Same as top / Not selected"%>
                                        </td>
                                        <td class="fw-bold">RM <%= String.format("%.2f", orderRs.getDouble("total_price"))%></td>
                                        <td>
                                            <% if ("paid".equalsIgnoreCase(payStatus)) { %>
                                            <span class="badge bg-success">PAID</span>
                                            <% } else if ("cancelled".equalsIgnoreCase(payStatus) || "cancelled".equalsIgnoreCase(orderRs.getString("order_status"))) { %>
                                            <span class="badge bg-danger">CANCELLED</span>
                                            <% } else { %>
                                            <span class="badge bg-warning text-dark">UNPAID</span>
                                            <% } %>
                                        </td>
                                        <td><span class="badge bg-info text-dark"><%= progStatus.toUpperCase()%></span></td>
                                        <td class="small">
                                            <% if (trackNo != null && !trackNo.trim().isEmpty()) { %>
                                            <strong><%= courier != null && !courier.trim().isEmpty() ? courier : "Courier"%></strong><br><%= trackNo%>
                                            <% } else { %>
                                            -
                                            <% } %>
                                        </td>
                                    </tr>
                                    <%
                                            }

                                            if (!hasCustomerOrders) {
                                    %>
                                    <tr>
                                        <td colspan="8" class="text-center text-muted py-4">No paid orders found for this customer.</td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                            e.printStackTrace();
                                    %>
                                    <tr>
                                        <td colspan="8" class="text-center text-danger py-4">Unable to load customer orders.</td>
                                    </tr>
                                    <%
                                        } finally {
                                            try { if (orderRs != null) orderRs.close(); } catch (Exception ignore) {}
                                            try { if (orderPs != null) orderPs.close(); } catch (Exception ignore) {}
                                            try { if (orderConn != null) orderConn.close(); } catch (Exception ignore) {}
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                        <% } %>
                    </div>

                    <% } else if ("design".equals(section)) { %>

                    <div class="row">
                        <div class="col-lg-6 mb-4">
                            <div class="card card-custom p-4">
                                <h5 class="text-success mb-3"><i class="fas fa-cut me-2"></i> Add New Design</h5>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="action" value="addDesign">

                                    <div class="mb-3">
                                        <label class="small fw-bold">Design Name</label>
                                        <input type="text" name="designName" class="form-control" placeholder="e.g. Baju Kurung Pahang" required>
                                    </div>

                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Category</label>
                                            <input type="text" name="designCategory" class="form-control" placeholder="e.g. Exclusive / Modern" required>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Size Guide Type</label>
                                            <select name="sizeGuideType" class="form-select" required>
                                                <option value="Baju Kurung Standard">Baju Kurung Standard</option>
                                                <option value="Baju Kurung Kedah">Baju Kurung Kedah</option>
                                                <option value="Jubah">Jubah</option>
                                                <option value="Baju Melayu">Baju Melayu</option>
                                                <option value="Kurta">Kurta</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Base Price / Tailoring Fee (RM)</label>
                                            <input type="number" name="basePrice" step="0.01" class="form-control" placeholder="0.00" required>
                                        </div>
                                    </div>

                                    <div class="mb-3">
                                        <label class="small fw-bold">Design Image</label>
                                        <input type="file" name="designImage" class="form-control" accept="image/*" required>
                                    </div>

                                    <button type="submit" class="btn btn-emerald w-100">Upload Design</button>
                                </form>
                            </div>
                        </div>
                    </div>

                    <div class="card card-custom p-4 mb-4">
                        <h5 class="text-success mb-3"><i class="fas fa-pen-to-square me-2"></i> Existing Designs</h5>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Image</th>
                                        <th>Design Name</th>
                                        <th>Category</th>
                                        <th>Size Guide Type</th>
                                        <th>Price (RM)</th>
                                        <th>Change Image</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Design d : designList) {%>
                                    <tr>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="designId" value="<%= d.getDesignId()%>">
                                    <td><img class="table-img" src="displayImage?name=<%= URLEncoder.encode(d.getImageName(), "UTF-8")%>" alt="Design Image"></td>
                                    <td><input type="text" name="designName" class="form-control" value="<%= d.getDesignName()%>" required></td>
                                    <td><input type="text" name="designCategory" class="form-control" value="<%= d.getCategory()%>" required></td>
                                    <td>
                                        <select name="sizeGuideType" class="form-select" required>
                                            <option value="Baju Kurung Standard" <%= "Baju Kurung Standard".equals(d.getSizeGuideType()) ? "selected" : ""%>>Baju Kurung Standard</option>
                                            <option value="Baju Kurung Kedah" <%= "Baju Kurung Kedah".equals(d.getSizeGuideType()) ? "selected" : ""%>>Baju Kurung Kedah</option>
                                            <option value="Jubah" <%= "Jubah".equals(d.getSizeGuideType()) ? "selected" : ""%>>Jubah</option>
                                            <option value="Baju Melayu" <%= "Baju Melayu".equals(d.getSizeGuideType()) ? "selected" : ""%>>Baju Melayu</option>
                                            <option value="Kurta" <%= "Kurta".equals(d.getSizeGuideType()) ? "selected" : ""%>>Kurta</option>
                                        </select>
                                    </td>
                                    <td><input type="number" name="basePrice" step="0.01" class="form-control" value="<%= d.getBasePrice()%>" required></td>
                                    <td><input type="file" name="designImage" class="form-control" accept="image/*"></td>
                                    <td><div class="d-flex gap-2"><button type="submit" name="action" value="updateDesign" class="btn btn-emerald btn-sm">Save</button><button type="submit" name="action" value="deleteDesign" class="btn btn-danger btn-sm" onclick="return confirm('Delete this design?')">Delete</button></div></td>
                                </form>
                                </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <% } else if ("material".equals(section)) { %>
                    <div class="row">
                        <div class="col-lg-6 mb-4">
                            <div class="card card-custom p-4 h-100">
                                <h5 class="text-success mb-3"><i class="fas fa-layer-group me-2"></i> Add Fabric Material</h5>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="action" value="addMaterial">

                                    <div class="mb-3">
                                        <label class="small fw-bold">Material Type</label>
                                        <input type="text" name="materialType" class="form-control" placeholder="e.g. Cotton / Silk / Chiffon" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="small fw-bold">Material Name</label>
                                        <input type="text" name="materialName" class="form-control" placeholder="e.g. Como Crepe" required>
                                    </div>

                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Category</label>
                                            <select name="materialCategory" class="form-select">
                                                <option value="Lelaki">Men</option>
                                                <option value="Perempuan">Women</option>
                                                <option value="Semua">All</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Price for 2 Meters (RM)</label>
                                            <input type="number" step="0.01" name="extraPrice" class="form-control" placeholder="0.00" required>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Stock Quantity (meter)</label>
                                            <input type="number" step="0.01" min="0" name="stockQuantity" class="form-control" placeholder="0.00" required>
                                        </div>
                                    </div>

                                    <div class="mb-4">
                                        <label class="small fw-bold">Material Image</label>
                                        <input type="file" name="materialImage" class="form-control" accept="image/*" required>
                                    </div>

                                    <div class="mt-auto">
                                        <button type="submit" class="btn btn-emerald w-100">Add Material</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>

                    <div class="card card-custom p-4 mb-4">
                        <h5 class="text-success mb-3"><i class="fas fa-pen-to-square me-2"></i> Existing Materials</h5>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Image</th>
                                        <th>Material Type</th>
                                        <th>Material Name</th>
                                        <th>Category</th>
                                        <th>2m Price (RM)</th>
                                        <th>Stock (meter)</th>
                                        <th>Change Image</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Material m : materialList) {%>
                                    <tr>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="materialId" value="<%= m.getMaterialId()%>">
                                    <td><img class="table-img" src="displayImage?type=material&name=<%= URLEncoder.encode(m.getImageName(), "UTF-8")%>" alt="Material Image"></td>
                                    <td><input type="text" name="materialType" class="form-control" value="<%= m.getMaterialType()%>" required></td>
                                    <td><input type="text" name="materialName" class="form-control" value="<%= m.getMaterialName()%>" required></td>
                                    <td>
                                        <select name="materialCategory" class="form-select">
                                            <option value="Lelaki" <%= "Lelaki".equals(m.getCategory()) ? "selected" : ""%>>Men</option>
                                            <option value="Perempuan" <%= "Perempuan".equals(m.getCategory()) ? "selected" : ""%>>Women</option>
                                            <option value="Semua" <%= "Semua".equals(m.getCategory()) ? "selected" : ""%>>All</option>
                                        </select>
                                    </td>
                                    <td><input type="number" name="extraPrice" step="0.01" class="form-control" value="<%= m.getExtraPrice()%>" required></td>
                                    <td>
                                        <input type="number" name="stockQuantity" step="0.01" min="0" class="form-control" value="<%= m.getStockQuantity()%>" required>
                                        <% if (m.getStockQuantity() <= 2) { %>
                                            <span class="badge bg-danger mt-1">LOW STOCK</span>
                                        <% } %>
                                    </td>
                                    <td><input type="file" name="materialImage" class="form-control" accept="image/*"></td>
                                    <td><div class="d-flex gap-2"><button type="submit" name="action" value="updateMaterial" class="btn btn-emerald btn-sm">Save</button><button type="submit" name="action" value="deleteMaterial" class="btn btn-danger btn-sm" onclick="return confirm('Delete this material?')">Delete</button></div></td>
                                </form>
                                </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <% } else if ("decoration".equals(section)) { %>

                    <div class="row">
                        <div class="col-lg-6 mb-4">
                            <div class="card card-custom p-4 h-100">
                                <h5 class="text-success mb-3"><i class="fas fa-wand-magic-sparkles me-2"></i> Add Decoration</h5>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="action" value="addDecoration">
                                    <div class="mb-3">
                                        <label class="small fw-bold">Decoration Name</label>
                                        <input type="text" name="decorationName" class="form-control" placeholder="e.g. Premium Crystal Beads" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="small fw-bold">Description</label>
                                        <textarea name="description" class="form-control" rows="3" placeholder="Short description shown to customer" required></textarea>
                                    </div>
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Additional Price (RM)</label>
                                            <input type="number" step="0.01" min="0" name="price" class="form-control" placeholder="0.00" required>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="small fw-bold">Decoration Image</label>
                                            <input type="file" name="decorationImage" class="form-control" accept="image/*" required>
                                        </div>
                                    </div>
                                    <button type="submit" class="btn btn-emerald w-100">Add Decoration</button>
                                </form>
                            </div>
                        </div>
                        <div class="col-lg-6 mb-4">
                            <div class="card card-custom p-4 h-100">
                                <h5 class="text-success mb-3"><i class="fas fa-info-circle me-2"></i> Decoration Notes</h5>
                                <div class="alert alert-info small mb-0">
                                    Decoration images added here will appear in the customer order form decoration gallery. Customer can choose one decoration and select the decoration area before checkout.
                                </div>
                                <div class="alert alert-warning small mt-3 mb-0">
                                    Suggested examples: Basic Pearl Beads, Premium Crystal Beads, Lace Decoration, Floral Embroidery.
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card card-custom p-4 mb-4">
                        <h5 class="text-success mb-3"><i class="fas fa-pen-to-square me-2"></i> Existing Decorations</h5>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead>
                                    <tr>
                                        <th>Image</th>
                                        <th>Decoration Name</th>
                                        <th>Description</th>
                                        <th>Price (RM)</th>
                                        <th>Status</th>
                                        <th>Change Image</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        Connection decConn = null;
                                        PreparedStatement decPs = null;
                                        ResultSet decRs = null;
                                        try {
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            decConn = fitstyle.util.DBConnection.getConnection();
                                            decPs = decConn.prepareStatement("SELECT decoration_id, decoration_name, description, COALESCE(decoration_type, 'Other') AS decoration_type, price, image_name, is_active FROM decorations ORDER BY decoration_type, decoration_name");
                                            decRs = decPs.executeQuery();
                                            boolean hasDecoration = false;
                                            while (decRs.next()) {
                                                hasDecoration = true;
                                    %>
                                    <tr>
                                <form action="DesignController" method="POST" enctype="multipart/form-data">
                                    <input type="hidden" name="decorationId" value="<%= decRs.getInt("decoration_id") %>">
                                    <td><img class="table-img" src="displayImage?type=decoration&name=<%= URLEncoder.encode(decRs.getString("image_name"), "UTF-8") %>" alt="Decoration Image"></td>
                                    <td><input type="text" name="decorationName" class="form-control" value="<%= decRs.getString("decoration_name") %>" required></td>
                                    <td><textarea name="description" class="form-control" rows="2" required><%= decRs.getString("description") != null ? decRs.getString("description") : "" %></textarea></td>
                                    <td><input type="number" name="price" step="0.01" min="0" class="form-control" value="<%= decRs.getDouble("price") %>" required></td>
                                    <td>
                                        <div class="form-check form-switch">
                                            <input class="form-check-input" type="checkbox" name="isActive" <%= decRs.getBoolean("is_active") ? "checked" : "" %>>
                                            <label class="form-check-label small">Active</label>
                                        </div>
                                    </td>
                                    <td><input type="file" name="decorationImage" class="form-control" accept="image/*"></td>
                                    <td>
                                        <div class="d-flex gap-2">
                                            <button type="submit" name="action" value="updateDecoration" class="btn btn-emerald btn-sm">Save</button>
                                            <button type="submit" name="action" value="deleteDecoration" class="btn btn-danger btn-sm" onclick="return confirm('Delete this decoration?')">Delete</button>
                                        </div>
                                    </td>
                                </form>
                                </tr>
                                    <%
                                            }
                                            if (!hasDecoration) {
                                    %>
                                    <tr><td colspan="8" class="text-center text-muted py-4">No decoration added yet.</td></tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                    %>
                                    <tr><td colspan="7" class="text-danger text-center py-4">Error: <%= e.getMessage() %></td></tr>
                                    <%
                                        } finally {
                                            try { if (decRs != null) decRs.close(); } catch (Exception ignore) {}
                                            try { if (decPs != null) decPs.close(); } catch (Exception ignore) {}
                                            try { if (decConn != null) decConn.close(); } catch (Exception ignore) {}
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <% } else if ("sales-report".equals(section)) { %>
                    <div class="card card-custom p-4 mb-4 report-area">
                        <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                            <div>
                                <h5 class="mb-1" style="color:#043927;"><i class="fas fa-chart-line me-2"></i> Monthly Sales Report</h5>
                                <p class="text-muted small mb-0">Only paid orders are included in this report.</p>
                            </div>
                            <button type="button" class="btn btn-emerald btn-sm no-print" onclick="window.print()"><i class="fas fa-print me-1"></i> Print Report</button>
                        </div>

                        <%
                            String reportMonth = request.getParameter("month");
                            if (reportMonth == null || reportMonth.trim().isEmpty()) {
                                java.text.SimpleDateFormat monthFmt = new java.text.SimpleDateFormat("yyyy-MM");
                                reportMonth = monthFmt.format(new java.util.Date());
                            }
                        %>
                        <form method="GET" action="tailor-dashboard.jsp" class="row g-2 align-items-end mb-4 no-print">
                            <input type="hidden" name="section" value="sales-report">
                            <div class="col-md-4">
                                <label class="small fw-bold">Select Month</label>
                                <input type="month" name="month" class="form-control" value="<%= reportMonth %>">
                            </div>
                            <div class="col-md-3">
                                <button type="submit" class="btn btn-emerald"><i class="fas fa-file-lines me-1"></i> Generate</button>
                            </div>
                        </form>

                        <%
                            int reportOrders = 0;
                            int reportCompleted = 0;
                            double reportRevenue = 0.00;
                            String popularDesign = "-";
                            String popularFabric = "-";
                            Connection reportConn = null;
                            PreparedStatement reportPs = null;
                            ResultSet reportRs = null;
                            try {
                                Class.forName("com.mysql.cj.jdbc.Driver");
                                reportConn = fitstyle.util.DBConnection.getConnection();
                                reportPs = reportConn.prepareStatement("SELECT COUNT(*) total_orders, SUM(CASE WHEN progress_status='completed' THEN 1 ELSE 0 END) completed_orders, SUM(COALESCE(total_price,0)+COALESCE(shipping_fee,0)) total_revenue FROM orders WHERE payment_status='paid' AND DATE_FORMAT(order_date,'%Y-%m')=?");
                                reportPs.setString(1, reportMonth);
                                reportRs = reportPs.executeQuery();
                                if (reportRs.next()) { reportOrders = reportRs.getInt("total_orders"); reportCompleted = reportRs.getInt("completed_orders"); reportRevenue = reportRs.getDouble("total_revenue"); }
                                reportRs.close(); reportPs.close();

                                reportPs = reportConn.prepareStatement("SELECT d.design_name, COUNT(*) cnt FROM orders o JOIN designs d ON o.design_id=d.design_id WHERE o.payment_status='paid' AND DATE_FORMAT(o.order_date,'%Y-%m')=? GROUP BY d.design_name ORDER BY cnt DESC LIMIT 1");
                                reportPs.setString(1, reportMonth);
                                reportRs = reportPs.executeQuery();
                                if (reportRs.next()) popularDesign = reportRs.getString("design_name");
                                reportRs.close(); reportPs.close();

                                reportPs = reportConn.prepareStatement("SELECT shirt_fabric_name AS fabric, COUNT(*) cnt FROM orders WHERE payment_status='paid' AND DATE_FORMAT(order_date,'%Y-%m')=? GROUP BY shirt_fabric_name ORDER BY cnt DESC LIMIT 1");
                                reportPs.setString(1, reportMonth);
                                reportRs = reportPs.executeQuery();
                                if (reportRs.next()) popularFabric = reportRs.getString("fabric");
                                reportRs.close(); reportPs.close();
                        %>
                        <div class="row g-3 mb-4">
                            <div class="col-md-3"><div class="mini-stat"><div class="label">Paid Orders</div><div class="value"><%= reportOrders %></div></div></div>
                            <div class="col-md-3"><div class="mini-stat"><div class="label">Completed Orders</div><div class="value"><%= reportCompleted %></div></div></div>
                            <div class="col-md-3"><div class="mini-stat"><div class="label">Revenue</div><div class="value">RM <%= String.format("%.2f", reportRevenue) %></div></div></div>
                            <div class="col-md-3"><div class="mini-stat"><div class="label">Avg Order Value</div><div class="value">RM <%= reportOrders > 0 ? String.format("%.2f", reportRevenue / reportOrders) : "0.00" %></div></div></div>
                        </div>
                        <div class="row g-3 mb-4">
                            <div class="col-md-6"><div class="alert alert-light border"><strong>Most Popular Design:</strong> <%= popularDesign != null ? popularDesign : "-" %></div></div>
                            <div class="col-md-6"><div class="alert alert-light border"><strong>Most Popular Fabric:</strong> <%= popularFabric != null ? popularFabric : "-" %></div></div>
                        </div>
                        <div class="table-responsive">
                            <table class="table table-bordered align-middle">
                                <thead><tr><th>Order</th><th>Date</th><th>Customer</th><th>Design</th><th>Progress</th><th>Total (RM)</th></tr></thead>
                                <tbody>
                                <%
                                    reportPs = reportConn.prepareStatement("SELECT o.order_id, o.order_date, o.progress_status, o.total_price, o.shipping_fee, u.full_name, d.design_name FROM orders o JOIN users u ON o.customer_id=u.user_id JOIN designs d ON o.design_id=d.design_id WHERE o.payment_status='paid' AND DATE_FORMAT(o.order_date,'%Y-%m')=? ORDER BY o.order_date DESC");
                                    reportPs.setString(1, reportMonth);
                                    reportRs = reportPs.executeQuery();
                                    boolean hasReportRows = false;
                                    while (reportRs.next()) { hasReportRows = true;
                                %>
                                <tr>
                                    <td>#FS-<%= reportRs.getInt("order_id") %></td>
                                    <td><%= reportRs.getTimestamp("order_date") %></td>
                                    <td><%= reportRs.getString("full_name") %></td>
                                    <td><%= reportRs.getString("design_name") %></td>
                                    <td><span class="badge bg-info text-dark"><%= reportRs.getString("progress_status") != null ? reportRs.getString("progress_status").toUpperCase() : "PENDING" %></span></td>
                                    <td>RM <%= String.format("%.2f", reportRs.getDouble("total_price") + reportRs.getDouble("shipping_fee")) %></td>
                                </tr>
                                <% } if (!hasReportRows) { %><tr><td colspan="6" class="text-center text-muted py-4">No paid orders for this month.</td></tr><% } %>
                                </tbody>
                            </table>
                        </div>
                        <% } catch (Exception e) { %>
                            <div class="alert alert-danger">Unable to load sales report: <%= e.getMessage() %></div>
                        <% } finally { try { if (reportRs != null) reportRs.close(); } catch(Exception ignore) {} try { if (reportPs != null) reportPs.close(); } catch(Exception ignore) {} try { if (reportConn != null) reportConn.close(); } catch(Exception ignore) {} } %>
                    </div>

                    
                    <% } else if ("shipping".equals(section)) { %>
                    <div class="card card-custom p-4 mb-4">
                        <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
                            <div>
                                <h5 class="mb-1" style="color:#043927;"><i class="fas fa-truck-fast me-2"></i>Delivery / Tracking</h5>
                                <p class="text-muted small mb-0">Orders completed by tailor will appear here. Add courier and tracking number before customer can mark the parcel as received.</p>
                            </div>
                            <a href="tailor-dashboard.jsp?section=tasks" class="btn btn-outline-secondary btn-sm">Back to Sewing Tasks</a>
                        </div>

                        <div class="row g-3">
                            <%
                                Connection connShip = null;
                                PreparedStatement psShip = null;
                                ResultSet rsShip = null;
                                try {
                                    Class.forName("com.mysql.cj.jdbc.Driver");
                                    connShip = fitstyle.util.DBConnection.getConnection();
                                    String sqlShip = "SELECT o.order_id, o.order_date, o.total_price, o.progress_status, o.delivery_status, "
                                            + "o.courier_name, o.tracking_number, o.tracking_updated_at, o.shipped_at, o.received_at, "
                                            + "o.delivery_address, o.shipping_address, o.shipping_state, "
                                            + "u.full_name, u.phone, u.email, u.address, d.design_name "
                                            + "FROM orders o "
                                            + "JOIN users u ON o.customer_id = u.user_id "
                                            + "JOIN designs d ON o.design_id = d.design_id "
                                            + "WHERE o.payment_status='paid' AND o.progress_status='completed' "
                                            + "ORDER BY CASE WHEN o.delivery_status='ready_to_ship' OR o.delivery_status IS NULL OR o.delivery_status='' THEN 0 WHEN o.delivery_status='shipped' THEN 1 ELSE 2 END, o.order_id DESC";
                                    psShip = connShip.prepareStatement(sqlShip);
                                    rsShip = psShip.executeQuery();
                                    boolean hasShip = false;
                                    while (rsShip.next()) {
                                        hasShip = true;
                                        String deliveryStatus = rsShip.getString("delivery_status");
                                        if (deliveryStatus == null || deliveryStatus.trim().isEmpty()) {
                                            deliveryStatus = "ready_to_ship";
                                        }
                                        String deliveryAddress = rsShip.getString("shipping_address");
                                        if (deliveryAddress == null || deliveryAddress.trim().isEmpty()) {
                                            deliveryAddress = rsShip.getString("delivery_address");
                                        }
                                        if (deliveryAddress == null || deliveryAddress.trim().isEmpty()) {
                                            deliveryAddress = rsShip.getString("address");
                                        }
                                        String courier = rsShip.getString("courier_name") != null ? rsShip.getString("courier_name") : "";
                                        String tracking = rsShip.getString("tracking_number") != null ? rsShip.getString("tracking_number") : "";
                            %>
                            <div class="col-12">
                                <div class="card border-0 shadow-sm" style="border-radius:14px;">
                                    <div class="card-body">
                                        <div class="d-flex justify-content-between align-items-start flex-wrap gap-2">
                                            <div>
                                                <h5 class="mb-1" style="color:#043927;">Order #FS-<%= rsShip.getInt("order_id") %></h5>
                                                <div class="small text-muted">
                                                    Customer: <strong><%= rsShip.getString("full_name") %></strong>
                                                    | Phone: <%= rsShip.getString("phone") != null ? rsShip.getString("phone") : "-" %>
                                                    | Design: <%= rsShip.getString("design_name") %>
                                                </div>
                                            </div>
                                            <div class="text-end">
                                                <% if ("received".equalsIgnoreCase(deliveryStatus)) { %>
                                                <span class="badge bg-success">RECEIVED BY CUSTOMER</span>
                                                <% } else if ("shipped".equalsIgnoreCase(deliveryStatus)) { %>
                                                <span class="badge bg-primary">POSTED / SHIPPED</span>
                                                <% } else { %>
                                                <span class="badge bg-warning text-dark">READY TO SHIP</span>
                                                <% } %>
                                                <div class="small text-muted mt-1">RM <%= String.format("%.2f", rsShip.getDouble("total_price")) %></div>
                                            </div>
                                        </div>

                                        <div class="row g-3 mt-2">
                                            <div class="col-md-6">
                                                <div class="p-3 bg-light rounded h-100">
                                                    <div class="fw-bold mb-2"><i class="fas fa-location-dot me-1"></i> Delivery Address</div>
                                                    <div class="small"><%= deliveryAddress != null && !deliveryAddress.trim().isEmpty() ? deliveryAddress : "-" %></div>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="p-3 bg-light rounded h-100">
                                                    <div class="fw-bold mb-2"><i class="fas fa-truck me-1"></i> Tracking Info</div>
                                                    <div class="small"><strong>Courier:</strong> <%= courier.trim().isEmpty() ? "-" : courier %></div>
                                                    <div class="small"><strong>Tracking No:</strong> <%= tracking.trim().isEmpty() ? "-" : tracking %></div>
                                                    <% if (rsShip.getTimestamp("shipped_at") != null) { %>
                                                    <div class="small text-muted">Posted at: <%= rsShip.getTimestamp("shipped_at") %></div>
                                                    <% } %>
                                                    <% if (rsShip.getTimestamp("received_at") != null) { %>
                                                    <div class="small text-muted">Received at: <%= rsShip.getTimestamp("received_at") %></div>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>

                                        <% if (!"received".equalsIgnoreCase(deliveryStatus)) { %>
                                        <form method="POST" action="tailor-dashboard.jsp?section=shipping" class="row g-2 align-items-end mt-3">
                                            <input type="hidden" name="action" value="updateShipping">
                                            <input type="hidden" name="orderId" value="<%= rsShip.getInt("order_id") %>">
                                            <div class="col-md-4">
                                                <label class="small fw-bold">Courier / Post Service</label>
                                                <input type="text" name="courierName" class="form-control form-control-sm" placeholder="J&T / PosLaju / DHL" value="<%= courier %>" required>
                                            </div>
                                            <div class="col-md-4">
                                                <label class="small fw-bold">Tracking Number</label>
                                                <input type="text" name="trackingNumber" class="form-control form-control-sm" placeholder="Enter tracking number" value="<%= tracking %>" required>
                                            </div>
                                            <div class="col-md-4 d-grid">
                                                <button type="submit" class="btn btn-emerald btn-sm">
                                                    <i class="fas fa-save me-1"></i> Save Tracking / Mark Posted
                                                </button>
                                            </div>
                                        </form>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                            <%
                                    }
                                    if (!hasShip) {
                            %>
                            <div class="col-12">
                                <div class="alert alert-info mb-0">No completed orders waiting for delivery tracking.</div>
                            </div>
                            <%
                                    }
                                } catch (Exception e) {
                            %>
                            <div class="col-12">
                                <div class="alert alert-danger">Error loading delivery orders: <%= e.getMessage() %><br><small>Please run the delivery update SQL if this mentions delivery_status, shipped_at, or received_at.</small></div>
                            </div>
                            <%
                                } finally {
                                    try { if (rsShip != null) rsShip.close(); } catch (Exception ignore) {}
                                    try { if (psShip != null) psShip.close(); } catch (Exception ignore) {}
                                    try { if (connShip != null) connShip.close(); } catch (Exception ignore) {}
                                }
                            %>
                        </div>
                    </div>

<% } else if ("reviews".equals(section)) { %>
                    <div class="card card-custom p-4 mb-4">
                        <h5 class="mb-1" style="color:#043927;"><i class="fas fa-star me-2"></i> Customer Reviews</h5>
                        <p class="text-muted small">Reviews can only be submitted after an order is completed.</p>
                        <div class="table-responsive">
                            <table class="table align-middle">
                                <thead><tr><th>Date</th><th>Order</th><th>Customer</th><th>Design</th><th>Rating</th><th>Review</th></tr></thead>
                                <tbody>
                                <%
                                    Connection revConn = null; PreparedStatement revPs = null; ResultSet revRs = null;
                                    try {
                                        Class.forName("com.mysql.cj.jdbc.Driver");
                                        revConn = fitstyle.util.DBConnection.getConnection();
                                        revPs = revConn.prepareStatement("SELECT r.created_at, r.order_id, r.rating, r.review_text, u.full_name, d.design_name FROM customer_reviews r JOIN users u ON r.customer_id=u.user_id JOIN designs d ON r.design_id=d.design_id ORDER BY r.created_at DESC");
                                        revRs = revPs.executeQuery();
                                        boolean hasReviews = false;
                                        while (revRs.next()) { hasReviews = true;
                                %>
                                <tr>
                                    <td class="small"><%= revRs.getTimestamp("created_at") %></td>
                                    <td>#FS-<%= revRs.getInt("order_id") %></td>
                                    <td><%= revRs.getString("full_name") %></td>
                                    <td><%= revRs.getString("design_name") %></td>
                                    <td style="color:#D4AF37;"><% for (int i=1;i<=5;i++){ %><i class="<%= i <= revRs.getInt("rating") ? "fas" : "far" %> fa-star"></i><% } %></td>
                                    <td><%= revRs.getString("review_text") != null ? revRs.getString("review_text") : "-" %></td>
                                </tr>
                                <% } if (!hasReviews) { %><tr><td colspan="6" class="text-center text-muted py-4">No reviews yet.</td></tr><% } %>
                                <% } catch (Exception e) { %><tr><td colspan="6" class="text-center text-danger">Unable to load reviews. Please run the review SQL update.</td></tr><% } finally { try { if (revRs != null) revRs.close(); } catch(Exception ignore) {} try { if (revPs != null) revPs.close(); } catch(Exception ignore) {} try { if (revConn != null) revConn.close(); } catch(Exception ignore) {} } %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <% } else if ("tasks".equals(section)) { %>
                    <div class="card card-custom p-4">
                        <h5 class="text-success mb-3"><i class="fas fa-list me-2"></i> Sewing Tasks</h5>
                        <p class="text-muted small">Only paid orders will appear here. Update the progress so customer can track their order.</p>

                        <%
                            String filterStatus = request.getParameter("filterStatus");
                            String searchOrder = request.getParameter("searchOrder");

                            if (filterStatus == null) {
                                filterStatus = "all";
                            }
                            if (searchOrder == null) {
                                searchOrder = "";
                            }
                        %>

                        <form method="GET" action="tailor-dashboard.jsp" class="row g-2 align-items-end mb-4">
                            <input type="hidden" name="section" value="tasks">
                            <div class="col-md-4">
                                <label class="small fw-bold">Search Order / Customer</label>
                                <input type="text" name="searchOrder" class="form-control form-control-sm"
                                       placeholder="Example: 20 or Aisyah"
                                       value="<%= searchOrder%>">
                            </div>
                            <div class="col-md-3">
                                <label class="small fw-bold">Filter Progress</label>
                                <select name="filterStatus" class="form-select form-select-sm">
                                    <option value="all" <%= "all".equals(filterStatus) ? "selected" : ""%>>All</option>
                                    <option value="pending" <%= "pending".equals(filterStatus) ? "selected" : ""%>>Pending</option>
                                    <option value="cutting" <%= "cutting".equals(filterStatus) ? "selected" : ""%>>Cutting</option>
                                    <option value="sewing" <%= "sewing".equals(filterStatus) ? "selected" : ""%>>Sewing</option>
                                    <option value="fitting" <%= "fitting".equals(filterStatus) ? "selected" : ""%>>Fitting</option>
                                    <option value="completed" <%= "completed".equals(filterStatus) ? "selected" : ""%>>Completed</option>
                                </select>
                            </div>
                            <div class="col-md-3 d-flex gap-2">
                                <button type="submit" class="btn btn-emerald btn-sm">
                                    <i class="fas fa-filter me-1"></i> Apply
                                </button>
                                <a href="tailor-dashboard.jsp?section=tasks" class="btn btn-outline-secondary btn-sm">
                                    Reset
                                </a>
                            </div>
                        </form>

                        <div class="row g-3">
                            <%
                                Connection connTask = null;
                                PreparedStatement psTask = null;
                                ResultSet rsTask = null;
                                try {
                                    Class.forName("com.mysql.cj.jdbc.Driver");
                                    connTask = fitstyle.util.DBConnection.getConnection();
                                    String sqlTask = "SELECT o.order_id, o.total_price, o.progress_status, o.progress_note, o.progress_updated_at, "
                                            + "o.shirt_fabric_name, o.skirt_fabric_name, o.shirt_fabric_type, o.skirt_fabric_type, "
                                            + "o.shirt_meter_used, o.skirt_meter_used, "
                                            + "o.top_size, o.bottom_size, o.fit_preference, "
                                            + "o.height_cm, o.weight_kg, o.special_request, o.order_date, o.payment_ref, "
                                            + "o.courier_name, o.tracking_number, o.tracking_updated_at, "
                                            + "o.decoration_name, o.decoration_area, o.decoration_notes, COALESCE(o.decoration_price,0) AS decoration_price, "
                                            + "u.full_name, u.phone, u.email, u.address, d.design_name "
                                            + "FROM orders o "
                                            + "JOIN users u ON o.customer_id = u.user_id "
                                            + "JOIN designs d ON o.design_id = d.design_id "
                                            + "WHERE o.payment_status='paid' ";

                                    if (!"all".equals(filterStatus)) {
                                        sqlTask += "AND (o.progress_status=? OR (o.progress_status IS NULL AND ?='pending')) ";
                                    }

                                    if (searchOrder != null && !searchOrder.trim().isEmpty()) {
                                        sqlTask += "AND (CAST(o.order_id AS CHAR) LIKE ? OR u.full_name LIKE ?) ";
                                    }

                                    sqlTask += "ORDER BY o.order_id DESC";

                                    psTask = connTask.prepareStatement(sqlTask);

                                    int paramIndex = 1;

                                    if (!"all".equals(filterStatus)) {
                                        psTask.setString(paramIndex++, filterStatus);
                                        psTask.setString(paramIndex++, filterStatus);
                                    }

                                    if (searchOrder != null && !searchOrder.trim().isEmpty()) {
                                        String keyword = "%" + searchOrder.trim() + "%";
                                        psTask.setString(paramIndex++, keyword);
                                        psTask.setString(paramIndex++, keyword);
                                    }

                                    rsTask = psTask.executeQuery();
                                    boolean hasTask = false;
                                    while (rsTask.next()) {
                                        hasTask = true;
                                        String currentProgress = rsTask.getString("progress_status");
                                        if (currentProgress == null || currentProgress.trim().isEmpty()) {
                                            currentProgress = "pending";
                                        }
                                        String progressNote = rsTask.getString("progress_note") != null ? rsTask.getString("progress_note") : "";
                                        String specialReq = rsTask.getString("special_request") != null && !rsTask.getString("special_request").trim().isEmpty() ? rsTask.getString("special_request") : "-";
                                        String fitPref = rsTask.getString("fit_preference") != null && !rsTask.getString("fit_preference").trim().isEmpty() ? rsTask.getString("fit_preference") : "-";
                                        String bottomFabric = rsTask.getString("skirt_fabric_name") != null && !rsTask.getString("skirt_fabric_name").trim().isEmpty() ? rsTask.getString("skirt_fabric_name") : "Same as top / Not selected";
                                        double topMeterUsed = rsTask.getDouble("shirt_meter_used");
                                        double bottomMeterUsed = rsTask.getDouble("skirt_meter_used");
                                        if (topMeterUsed <= 0) {
                                            topMeterUsed = 2.00;
                                        }
                                        if (bottomMeterUsed <= 0) {
                                            bottomMeterUsed = 2.00;
                                        }
                                        double topExtraMeter = topMeterUsed > 2 ? topMeterUsed - 2 : 0.00;
                                        double bottomExtraMeter = bottomMeterUsed > 2 ? bottomMeterUsed - 2 : 0.00;
                            %>
                            <div class="col-12">
                                <div class="card border-0 shadow-sm" style="border-radius: 14px;">
                                    <div class="card-body">
                                        <div class="d-flex justify-content-between align-items-start flex-wrap gap-2 mb-3">
                                            <div>
                                                <h5 class="mb-1" style="color:#043927;">Order #FS-<%= rsTask.getInt("order_id")%></h5>
                                                <div class="text-muted small">
                                                    Customer: <strong><%= rsTask.getString("full_name")%></strong>
                                                    | Phone: <%= rsTask.getString("phone") != null ? rsTask.getString("phone") : "-"%>
                                                    | Date: <%= rsTask.getTimestamp("order_date")%>
                                                </div>
                                            </div>
                                            <div class="text-end">
                                                <div class="fw-bold" style="color:#043927;">RM <%= String.format("%.2f", rsTask.getDouble("total_price"))%></div>
                                                <span class="badge bg-success">PAID</span>
                                            </div>
                                        </div>

                                        <div class="row g-3 mb-3">
                                            <div class="col-md-4">
                                                <div class="p-3 bg-light rounded h-100">
                                                    <div class="fw-bold mb-2"><i class="fas fa-shirt me-1"></i> Order Details</div>
                                                    <div class="small"><strong>Design:</strong> <%= rsTask.getString("design_name")%></div>
                                                    <div class="small"><strong>Top Fabric:</strong> <%= rsTask.getString("shirt_fabric_name") != null ? rsTask.getString("shirt_fabric_name") : "-"%></div>
                                                    <div class="small text-muted">
                                                        Top Fabric Meter: <%= String.format("%.2f", topMeterUsed)%>m
                                                        <% if (topExtraMeter > 0) { %>
                                                            <span class="badge bg-warning text-dark ms-1">Extra <%= String.format("%.2f", topExtraMeter)%>m</span>
                                                        <% } %>
                                                    </div>
                                                    <div class="small"><strong>Bottom Fabric:</strong> <%= bottomFabric%></div>
                                                    <div class="small text-muted">
                                                        Bottom Fabric Meter: <%= String.format("%.2f", bottomMeterUsed)%>m
                                                        <% if (bottomExtraMeter > 0) { %>
                                                            <span class="badge bg-warning text-dark ms-1">Extra <%= String.format("%.2f", bottomExtraMeter)%>m</span>
                                                        <% } %>
                                                    </div>
                                                    <div class="small mt-2">
                                                        <strong>Total Fabric Needed:</strong> <%= String.format("%.2f", topMeterUsed + bottomMeterUsed)%>m
                                                    </div>
                                                    <div class="small mt-2"><strong>Decoration:</strong> <%= rsTask.getString("decoration_name") != null && !rsTask.getString("decoration_name").trim().isEmpty() ? rsTask.getString("decoration_name") : "No Decoration"%></div>
                                                    <% if (rsTask.getString("decoration_name") != null && !rsTask.getString("decoration_name").trim().isEmpty()) { %>
                                                    <div class="small text-muted">Placement: <%= rsTask.getString("decoration_area") != null ? rsTask.getString("decoration_area") : "-"%> | Cost: RM <%= String.format("%.2f", rsTask.getDouble("decoration_price"))%></div>
                                                    <% if (rsTask.getString("decoration_notes") != null && !rsTask.getString("decoration_notes").trim().isEmpty()) { %>
                                                    <div class="small text-muted"><strong>Decoration Notes:</strong> <%= rsTask.getString("decoration_notes") %></div>
                                                    <% } %>
                                                    <% } %>
                                                </div>
                                            </div>
                                            <div class="col-md-4">
                                                <div class="p-3 bg-light rounded h-100">
                                                    <div class="fw-bold mb-2"><i class="fas fa-ruler-combined me-1"></i> Size Details</div>
                                                    <div class="small"><strong>Top Size:</strong> <%= rsTask.getString("top_size") != null && !rsTask.getString("top_size").trim().isEmpty() ? rsTask.getString("top_size") : "-"%></div>
                                                    <div class="small"><strong>Bottom Size:</strong> <%= rsTask.getString("bottom_size") != null && !rsTask.getString("bottom_size").trim().isEmpty() ? rsTask.getString("bottom_size") : "-"%></div>
                                                    <div class="small"><strong>Fit:</strong> <%= fitPref%></div>
                                                    <div class="small"><strong>Height:</strong> <%= rsTask.getObject("height_cm") != null ? rsTask.getDouble("height_cm") + " cm" : "-"%></div>
                                                    <div class="small"><strong>Weight:</strong> <%= rsTask.getObject("weight_kg") != null ? rsTask.getDouble("weight_kg") + " kg" : "-"%></div>
                                                </div>
                                            </div>
                                            <div class="col-md-4">
                                                <div class="p-3 bg-light rounded h-100">
                                                    <div class="fw-bold mb-2"><i class="fas fa-note-sticky me-1"></i> Customer Request</div>
                                                    <div class="small"><%= specialReq%></div>
                                                    <hr class="my-2">
                                                    <div class="small"><strong>Payment Ref:</strong> <%= rsTask.getString("payment_ref") != null ? rsTask.getString("payment_ref") : "-"%></div>
                                                    <div class="small"><strong>Address:</strong> <%= rsTask.getString("address") != null ? rsTask.getString("address") : "-"%></div>
                                                    <div class="small"><strong>Courier:</strong> <%= rsTask.getString("courier_name") != null && !rsTask.getString("courier_name").trim().isEmpty() ? rsTask.getString("courier_name") : "-"%></div>
                                                    <div class="small"><strong>Tracking No:</strong> <%= rsTask.getString("tracking_number") != null && !rsTask.getString("tracking_number").trim().isEmpty() ? rsTask.getString("tracking_number") : "-"%></div>
                                                    <%
                                                        String phoneRaw = rsTask.getString("phone") != null ? rsTask.getString("phone").replaceAll("[^0-9]", "") : "";
                                                        if (phoneRaw.startsWith("0")) {
                                                            phoneRaw = "6" + phoneRaw;
                                                        }
                                                    %>
                                                    <% if (!phoneRaw.isEmpty()) { %>
                                                    <a class="btn btn-success btn-sm mt-2" target="_blank"
                                                       href="https://wa.me/<%= phoneRaw%>">
                                                        <i class="fab fa-whatsapp me-1"></i> WhatsApp Customer
                                                    </a>
                                                    <% } %>
                                                </div>
                                            </div>
                                        </div>

                                        <form method="POST" action="tailor-dashboard.jsp?section=tasks" class="row g-2 align-items-end">
                                            <input type="hidden" name="action" value="updateProgress">
                                            <input type="hidden" name="orderId" value="<%= rsTask.getInt("order_id")%>">
                                            <div class="col-md-3">
                                                <label class="small fw-bold">Progress Status</label>
                                                <select id="progressStatus_<%= rsTask.getInt("order_id")%>" name="progressStatus" class="form-select form-select-sm" onchange="updateAutoNote('<%= rsTask.getInt("order_id")%>')">
                                                    <option value="pending" <%= "pending".equals(currentProgress) ? "selected" : ""%>>Pending</option>
                                                    <option value="cutting" <%= "cutting".equals(currentProgress) ? "selected" : ""%>>Cutting</option>
                                                    <option value="sewing" <%= "sewing".equals(currentProgress) ? "selected" : ""%>>Sewing</option>
                                                    <option value="fitting" <%= "fitting".equals(currentProgress) ? "selected" : ""%>>Fitting</option>
                                                    <option value="completed" <%= "completed".equals(currentProgress) ? "selected" : ""%>>Completed</option>
                                                </select>
                                                <% if (rsTask.getTimestamp("progress_updated_at") != null) {%>
                                                <div class="small text-muted mt-1">Updated: <%= rsTask.getTimestamp("progress_updated_at")%></div>
                                                <div class="small text-muted">Estimated completion: 7 days after progress update</div>
                                                <% } else { %>
                                                <div class="small text-muted mt-1">Estimated completion: After tailor starts sewing</div>
                                                <% }%>
                                            </div>
                                            <div class="col-md-9">
                                                <label class="small fw-bold">Progress Note for Customer</label>
                                                <textarea id="progressNote_<%= rsTask.getInt("order_id")%>" name="progressNote" class="form-control form-control-sm" rows="2"><%= progressNote%></textarea>
                                                <div class="small text-muted mt-1">
                                                    Auto note will appear when status changes. Tailor can still edit it.
                                                </div>
                                            </div>
                                            <div class="col-md-12 d-grid mt-2">
                                                <button type="submit" class="btn btn-emerald btn-sm">Update Progress</button>
                                            </div>
                                        </form>
                                    </div>
                                </div>
                            </div>
                            <%
                                }
                                if (!hasTask) {
                            %>
                            <div class="col-12 text-center text-muted py-4">No paid orders yet.</div>
                            <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            %>
                            <div class="col-12 text-danger text-center py-4">Unable to load sewing tasks.</div>
                            <%
                                } finally {
                                    try {
                                        if (rsTask != null) {
                                            rsTask.close();
                                        }
                                    } catch (Exception ignore) {
                                    }
                                    try {
                                        if (psTask != null) {
                                            psTask.close();
                                        }
                                    } catch (Exception ignore) {
                                    }
                                    try {
                                        if (connTask != null) {
                                            connTask.close();
                                        }
                                    } catch (Exception ignore) {
                                    }
                                }
                            %>
                        </div>
                    </div>
                    <% }%>
                </main>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

        <script>
                                                    function updateAutoNote(orderId) {
                                                        var status = document.getElementById("progressStatus_" + orderId).value;
                                                        var note = document.getElementById("progressNote_" + orderId);

                                                        var autoText = "";

                                                        if (status === "pending") {
                                                            autoText = "Payment received. Waiting for tailor to start sewing task.";
                                                        } else if (status === "cutting") {
                                                            autoText = "Your fabric is currently being cut according to the selected design and size.";
                                                        } else if (status === "sewing") {
                                                            autoText = "Your outfit is currently in the sewing process.";
                                                        } else if (status === "fitting") {
                                                            autoText = "Your outfit is almost ready and is now in the fitting/checking stage.";
                                                        } else if (status === "completed") {
                                                            autoText = "Your order has been completed and is ready for collection/delivery.";
                                                        } else {
                                                            autoText = "Your order progress has been updated.";
                                                        }

                                                        note.value = autoText;
                                                    }

                                                    </script>
    </body>
</html>