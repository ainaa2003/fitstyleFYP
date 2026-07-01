<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<!DOCTYPE html>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int orderId = 0;
    try {
        orderId = Integer.parseInt(request.getParameter("orderId"));
    } catch (Exception e) {
        response.sendRedirect("order-history.jsp?msg=order_not_found");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String designName = "";
    int designId = 0;
    boolean allowed = false;
    boolean alreadyReviewed = false;
    String errorMsg = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            int rating = Integer.parseInt(request.getParameter("rating"));
            String reviewText = request.getParameter("reviewText");

            ps = conn.prepareStatement("SELECT o.design_id FROM orders o WHERE o.order_id=? AND o.customer_id=? AND o.payment_status='paid' AND o.progress_status='completed' AND o.delivery_status='received'");
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            rs = ps.executeQuery();
            if (!rs.next()) {
                response.sendRedirect("order-history.jsp?msg=not_allowed");
                return;
            }
            designId = rs.getInt("design_id");
            rs.close();
            ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM customer_reviews WHERE order_id=?");
            ps.setInt(1, orderId);
            rs = ps.executeQuery();
            rs.next();
            if (rs.getInt(1) > 0) {
                response.sendRedirect("order-history.jsp?msg=review_exists");
                return;
            }
            rs.close();
            ps.close();

            ps = conn.prepareStatement("INSERT INTO customer_reviews (order_id, customer_id, design_id, rating, review_text) VALUES (?,?,?,?,?)");
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            ps.setInt(3, designId);
            ps.setInt(4, rating);
            ps.setString(5, reviewText);
            ps.executeUpdate();

            response.sendRedirect("order-history.jsp?msg=review_added");
            return;
        }

        ps = conn.prepareStatement("SELECT o.design_id, d.design_name, (SELECT COUNT(*) FROM customer_reviews r WHERE r.order_id=o.order_id) review_count FROM orders o JOIN designs d ON o.design_id=d.design_id WHERE o.order_id=? AND o.customer_id=? AND o.payment_status='paid' AND o.progress_status='completed' AND o.delivery_status='received'");
        ps.setInt(1, orderId);
        ps.setInt(2, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            allowed = true;
            designId = rs.getInt("design_id");
            designName = rs.getString("design_name");
            alreadyReviewed = rs.getInt("review_count") > 0;
        }
    } catch (Exception e) {
        errorMsg = e.getMessage();
    } finally {
        try { if (rs != null) rs.close(); } catch(Exception ignore) {}
        try { if (ps != null) ps.close(); } catch(Exception ignore) {}
        try { if (conn != null) conn.close(); } catch(Exception ignore) {}
    }
%>
<html>
<head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>Rate & Review | FitStyle</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body{background:#f4f7f6;font-family:Poppins,sans-serif}
        .card{max-width:720px;margin:40px auto;border:0;border-radius:18px;box-shadow:0 8px 25px rgba(0,0,0,.08)}
        .header{background:#043927;color:#D4AF37;padding:22px;border-radius:18px 18px 0 0}
    </style>
</head>
<body>
<%@include file="includes/navbar.jsp" %>
<div class="container">
    <div class="card">
        <div class="header"><h4 class="mb-0"><i class="fas fa-star me-2"></i>Rate & Review</h4></div>
        <div class="card-body p-4">
            <% if (errorMsg != null && !errorMsg.trim().isEmpty()) { %>
                <div class="alert alert-danger">Error: <%= errorMsg %><br><small>Please run the review SQL update if this mentions customer_reviews.</small></div>
                <a href="order-history.jsp" class="btn btn-secondary">Back</a>
            <% } else if (!allowed) { %>
                <div class="alert alert-warning">Review is only available after you mark the order as received.</div>
                <a href="order-history.jsp" class="btn btn-secondary">Back</a>
            <% } else if (alreadyReviewed) { %>
                <div class="alert alert-success">You have already reviewed this order.</div>
                <a href="order-history.jsp" class="btn btn-secondary">Back</a>
            <% } else { %>
                <p class="text-muted">Order <strong>#FS-<%= orderId %></strong> - <strong><%= designName %></strong></p>
                <form method="POST" action="review.jsp?orderId=<%= orderId %>">
                    <label class="form-label fw-bold">Rating</label>
                    <select name="rating" class="form-select mb-3" required>
                        <option value="5">★★★★★ Excellent</option>
                        <option value="4">★★★★ Good</option>
                        <option value="3">★★★ Average</option>
                        <option value="2">★★ Poor</option>
                        <option value="1">★ Very Poor</option>
                    </select>
                    <label class="form-label fw-bold">Review</label>
                    <textarea name="reviewText" class="form-control" rows="5" placeholder="Write your feedback about the tailoring quality, fabric, and service." required></textarea>
                    <div class="mt-3 d-flex gap-2">
                        <button class="btn btn-success" type="submit"><i class="fas fa-paper-plane me-1"></i> Submit Review</button>
                        <a href="order-history.jsp" class="btn btn-outline-secondary">Cancel</a>
                    </div>
                </form>
            <% } %>
        </div>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
