<%--
    Document   : measurement-record
    Purpose    : Customer measurement history from previous orders
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
%>
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Measurement Records | FitStyle</title>
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
            .table-card {
                background: white;
                border: none;
                border-radius: 15px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.06);
                overflow: hidden;
            }
            .thead-custom {
                background-color: var(--primary);
                color: var(--gold);
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
                            <li class="nav-item"><a class="nav-link" href="customer-dashboard.jsp"><i class="fas fa-home me-2"></i> Dashboard</a></li>
                            <li class="nav-item"><a class="nav-link" href="order-history.jsp"><i class="fas fa-shopping-bag me-2"></i> My Orders</a></li>
                            <li class="nav-item"><a class="nav-link active" href="measurement-record.jsp"><i class="fas fa-ruler-combined me-2"></i> Measurement Records</a></li>
                            <li class="nav-item"><a class="nav-link" href="profile.jsp"><i class="fas fa-id-card me-2"></i> My Profile</a></li>
                            <li class="nav-item"><a class="nav-link" href="auth-controller?action=logout"><i class="fas fa-sign-out-alt me-2"></i> Logout</a></li>
                        </ul>
                    </div>
                </nav>

                <main class="col-md-10 main-content">
                    <div class="d-flex justify-content-between align-items-center pt-3 pb-2 mb-4 border-bottom flex-wrap gap-2">
                        <div>
                            <h1 class="h2 mb-1">Measurement Records</h1>
                            <p class="text-muted mb-0">Review measurements saved from your previous orders.</p>
                        </div>
                        <a href="browse-designs.jsp" class="btn btn-success"><i class="fas fa-plus me-2"></i> Order New Outfit</a>
                    </div>

                    <div class="card table-card">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="thead-custom">
                                    <tr>
                                        <th class="ps-4">Order</th>
                                        <th>Date</th>
                                        <th>Design</th>
                                        <th>Top Size</th>
                                        <th>Bottom Size</th>
                                        <th>Fit</th>
                                        <th>Height</th>
                                        <th>Weight</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        Connection conn = null;
                                        PreparedStatement ps = null;
                                        ResultSet rs = null;
                                        boolean hasData = false;

                                        try {
                                            Class.forName("com.mysql.cj.jdbc.Driver");
                                            conn = fitstyle.util.DBConnection.getConnection();

                                            String sql = "SELECT o.order_id, o.order_date, o.top_size, o.bottom_size, o.fit_preference, "
                                                    + "o.height_cm, o.weight_kg, d.design_name "
                                                    + "FROM orders o LEFT JOIN designs d ON o.design_id=d.design_id "
                                                    + "WHERE o.customer_id=? ORDER BY o.order_id DESC";

                                            ps = conn.prepareStatement(sql);
                                            ps.setInt(1, userId);
                                            rs = ps.executeQuery();

                                            while (rs.next()) {
                                                hasData = true;
                                    %>
                                    <tr>
                                        <td class="ps-4 fw-bold">#FS-<%= rs.getInt("order_id")%></td>
                                        <td><%= rs.getTimestamp("order_date") != null ? rs.getTimestamp("order_date").toString().substring(0, 10) : "-"%></td>
                                        <td><%= rs.getString("design_name") != null ? rs.getString("design_name") : "-"%></td>
                                        <td><%= rs.getString("top_size") != null && !rs.getString("top_size").trim().isEmpty() ? rs.getString("top_size") : "-"%></td>
                                        <td><%= rs.getString("bottom_size") != null && !rs.getString("bottom_size").trim().isEmpty() ? rs.getString("bottom_size") : "-"%></td>
                                        <td><%= rs.getString("fit_preference") != null && !rs.getString("fit_preference").trim().isEmpty() ? rs.getString("fit_preference") : "-"%></td>
                                        <td><%= rs.getObject("height_cm") != null ? rs.getDouble("height_cm") + " cm" : "-"%></td>
                                        <td><%= rs.getObject("weight_kg") != null ? rs.getDouble("weight_kg") + " kg" : "-"%></td>
                                    </tr>
                                    <%
                                            }
                                        } catch (Exception e) {
                                    %>
                                    <tr><td colspan="8" class="text-danger text-center py-4">Unable to load measurement records.</td></tr>
                                    <%
                                        } finally {
                                            try { if (rs != null) rs.close(); } catch (Exception ignore) {}
                                            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
                                            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
                                        }

                                        if (!hasData) {
                                    %>
                                    <tr><td colspan="8" class="text-center text-muted py-4">No measurement records yet.</td></tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </main>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
