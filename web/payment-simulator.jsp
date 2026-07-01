<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>

<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
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

    private String methodIcon(String method) {
        if ("Debit/Credit Card".equalsIgnoreCase(method)) return "fa-credit-card";
        if ("QR Transfer".equalsIgnoreCase(method)) return "fa-qrcode";
        return "fa-building-columns";
    }
%>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?msg=Please login first");
        return;
    }

    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        response.sendRedirect("order-history.jsp");
        return;
    }

    int customerId = Integer.parseInt(session.getAttribute("userId").toString());
    String idsParam = request.getParameter("ids") == null ? "" : request.getParameter("ids").trim();
    String addressIdParam = request.getParameter("addressId") == null ? "" : request.getParameter("addressId").trim();
    String paymentMethod = request.getParameter("paymentMethod") == null ? "" : request.getParameter("paymentMethod").trim();

    boolean validMethod = "FPX Online Banking".equalsIgnoreCase(paymentMethod)
            || "Debit/Credit Card".equalsIgnoreCase(paymentMethod)
            || "QR Transfer".equalsIgnoreCase(paymentMethod);

    if (idsParam.isEmpty() || addressIdParam.isEmpty() || !validMethod) {
        response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=missing_payment_details");
        return;
    }

    ArrayList<Integer> selectedIds = new ArrayList<Integer>();
    String[] parts = idsParam.split(",");
    for (String part : parts) {
        try {
            int val = Integer.parseInt(part.trim());
            if (!selectedIds.contains(val)) selectedIds.add(val);
        } catch (Exception ignore) {}
    }

    int addressId = 0;
    try {
        addressId = Integer.parseInt(addressIdParam);
    } catch (Exception ignore) {}

    if (selectedIds.isEmpty() || addressId <= 0) {
        response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=missing_payment_details");
        return;
    }

    double subtotal = 0.00;
    double shipping = 0.00;
    double grandTotal = 0.00;
    int validOrderCount = 0;
    String region = "WEST";
    String regionName = "Semenanjung Malaysia";
    String paymentRef = "SIM" + String.valueOf(new java.util.Date().getTime());

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();

        ps = conn.prepareStatement("SELECT region FROM customer_addresses WHERE customer_id=? AND address_id=?");
        ps.setInt(1, customerId);
        ps.setInt(2, addressId);
        rs = ps.executeQuery();
        if (!rs.next()) {
            response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=address_not_found");
            return;
        }
        region = rs.getString("region") == null ? "WEST" : rs.getString("region");
        regionName = isEastMalaysia(region) ? "Sabah/Sarawak" : "Semenanjung Malaysia";
        rs.close();
        ps.close();

        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < selectedIds.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }

        ps = conn.prepareStatement("SELECT order_id, total_price FROM orders WHERE customer_id=? AND order_id IN (" + placeholders.toString() + ") AND payment_status <> 'paid' AND (order_status IS NULL OR order_status <> 'cancelled')");
        ps.setInt(1, customerId);
        for (int i = 0; i < selectedIds.size(); i++) {
            ps.setInt(i + 2, selectedIds.get(i));
        }
        rs = ps.executeQuery();
        while (rs.next()) {
            validOrderCount++;
            subtotal += rs.getDouble("total_price");
        }
        rs.close();
        ps.close();

        if (validOrderCount == 0) {
            response.sendRedirect("order-history.jsp?msg=no_unpaid_order");
            return;
        }

        shipping = calcShipping(region, validOrderCount);
        grandTotal = subtotal + shipping;
    } catch (Exception e) {
        response.sendRedirect("payment.jsp?ids=" + idsParam + "&msg=payment_simulator_error");
        return;
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (conn != null) conn.close(); } catch (Exception ignore) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>Payment Simulation | FitStyle</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background:#f4f7f6; font-family:'Poppins', sans-serif; color:#043927; }
        .gateway-card { max-width:760px; margin:45px auto; border:none; border-radius:18px; overflow:hidden; box-shadow:0 8px 28px rgba(0,0,0,.12); }
        .gateway-header { background:#043927; color:#D4AF37; padding:24px; }
        .gateway-body { padding:28px; background:#fff; }
        .secure-box { border:1px solid #e9ecef; border-radius:14px; padding:18px; background:#f8f9fa; }
        .amount { font-size:2rem; font-weight:800; color:#043927; }
        .btn-approve { background:#198754; color:#fff; border:none; font-weight:700; }
        .btn-approve:hover { background:#146c43; color:#fff; }
        .processing-overlay {
            display:none; position:fixed; inset:0; background:rgba(255,255,255,.88);
            z-index:9999; align-items:center; justify-content:center; text-align:center;
        }
    </style>
</head>
<body>
<%@include file="includes/navbar.jsp" %>

<div class="container">
    <div class="card gateway-card">
        <div class="gateway-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
                <h3 class="mb-1"><i class="fas <%= methodIcon(paymentMethod) %> me-2"></i>FitStyle Payment Gateway</h3>
                <div class="small text-white-50">Secure Payment Simulation</div>
            </div>
            <span class="badge bg-warning text-dark">DEMO ONLY</span>
        </div>

        <div class="gateway-body">
            <div class="alert alert-info small">
                <i class="fas fa-circle-info me-1"></i>
                This is a simulated payment for academic purposes. No real transaction will be made.
            </div>

            <div class="secure-box mb-4">
                <div class="row g-3">
                    <div class="col-md-6">
                        <div class="text-muted small">Payment Reference</div>
                        <div class="fw-bold">#<%= paymentRef %></div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small">Payment Method</div>
                        <div class="fw-bold"><%= esc(paymentMethod) %></div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small">Selected Orders</div>
                        <div class="fw-bold"><%= validOrderCount %> order(s)</div>
                    </div>
                    <div class="col-md-6">
                        <div class="text-muted small">Shipping Region</div>
                        <div class="fw-bold"><%= regionName %></div>
                    </div>
                </div>
            </div>

            <div class="text-center mb-4">
                <div class="text-muted small">Amount to Pay</div>
                <div class="amount">RM <%= String.format("%.2f", grandTotal) %></div>
                <div class="small text-muted">
                    Subtotal RM <%= String.format("%.2f", subtotal) %> + Shipping RM <%= String.format("%.2f", shipping) %>
                </div>
            </div>

            <% if ("FPX Online Banking".equalsIgnoreCase(paymentMethod)) { %>
            <div class="mb-3">
                <label class="form-label fw-bold">Select Bank</label>
                <select class="form-select" required>
                    <option>Maybank2u</option>
                    <option>CIMB Clicks</option>
                    <option>Bank Islam</option>
                    <option>RHB Now</option>
                    <option>Public Bank</option>
                </select>
            </div>
            <% } else if ("Debit/Credit Card".equalsIgnoreCase(paymentMethod)) { %>
            <div class="row g-3 mb-3">
                <div class="col-md-12">
                    <label class="form-label fw-bold">Card Number</label>
                    <input type="text" class="form-control" value="4111 1111 1111 1111" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold">Expiry</label>
                    <input type="text" class="form-control" value="12/30" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold">CVV</label>
                    <input type="password" class="form-control" value="123" readonly>
                </div>
            </div>
            <% } else { %>
            <div class="text-center mb-3">
                <div class="border rounded p-4 bg-light">
                    <i class="fas fa-qrcode fa-5x mb-3"></i>
                    <div class="fw-bold">Scan QR Transfer</div>
                    <div class="small text-muted">Demo QR only. Click approve to complete the simulation.</div>
                </div>
            </div>
            <% } %>

            <form id="approveForm" action="payment_success.jsp" method="POST">
                <input type="hidden" name="ids" value="<%= esc(idsParam) %>">
                <input type="hidden" name="addressId" value="<%= addressId %>">
                <input type="hidden" name="paymentMethod" value="<%= esc(paymentMethod) %>">
                <input type="hidden" name="paymentRef" value="<%= paymentRef %>">
                <input type="hidden" name="simulatorApproved" value="yes">

                <button type="submit" class="btn btn-approve w-100 p-2" onclick="return showProcessing();">
                    <i class="fas fa-check-circle me-1"></i> Approve Payment
                </button>
            </form>

            <form action="payment.jsp" method="GET" class="mt-2">
                <input type="hidden" name="ids" value="<%= esc(idsParam) %>">
                <input type="hidden" name="msg" value="payment_cancelled">
                <button type="submit" class="btn btn-outline-danger w-100 p-2 fw-bold">
                    <i class="fas fa-times-circle me-1"></i> Cancel Payment
                </button>
            </form>
        </div>
    </div>
</div>

<div class="processing-overlay" id="processingOverlay">
    <div>
        <div class="spinner-border text-success mb-3" role="status"></div>
        <h5 class="fw-bold">Processing Payment...</h5>
        <div class="text-muted">Please wait while we verify the simulated transaction.</div>
    </div>
</div>

<script>
    function showProcessing() {
        document.getElementById('processingOverlay').style.display = 'flex';
        setTimeout(function () {
            document.getElementById('approveForm').submit();
        }, 1800);
        return false;
    }
</script>
</body>
</html>
