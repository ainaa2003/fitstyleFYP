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

    private String regionDisplay(String region) {
        return isEastMalaysia(region) ? "Sabah/Sarawak" : "Semenanjung Malaysia";
    }
%>

<!DOCTYPE html>
<html>
<head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>Checkout & Payment | FitStyle</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background:#f8f9fa; font-family:'Poppins', sans-serif; }
        .payment-card { max-width: 900px; width: 100%; border-radius: 15px; border: none; }
        .brand-title { color:#043927; font-family:'Playfair Display', serif; font-weight:bold; }
        .section-title { color:#043927; border-left:3px solid #D4AF37; padding-left:8px; font-weight:bold; }
        .order-item { border:1px solid #e9ecef; border-radius:12px; padding:14px; margin-bottom:12px; background:#fff; }
        .summary-box { background:#fff8e1; border:1px solid #f1d36b; border-radius:12px; padding:15px; }
        .address-card { border:2px solid #e9ecef; border-radius:12px; padding:14px; background:#fff; cursor:pointer; height:100%; transition:.2s; }
        .address-card:hover { border-color:#D4AF37; }
        .address-radio:checked + .address-card { border-color:#043927; box-shadow:0 0 0 .15rem rgba(4,57,39,.12); }
        .address-radio { display:none; }
        .badge-region { background:#043927; color:#D4AF37; }
    </style>
</head>

<body>
<%@include file="includes/navbar.jsp" %>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?msg=Please login first");
        return;
    }

    if ("tailor".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("tailor-dashboard.jsp?section=dashboard&msg=Tailor cannot make customer payment.");
        return;
    }

    int customerId = Integer.parseInt(session.getAttribute("userId").toString());

    ArrayList<Integer> selectedIds = new ArrayList<Integer>();
    String[] orderIds = request.getParameterValues("orderIds");
    String singleId = request.getParameter("id");
    String idsParam = request.getParameter("ids");

    if (idsParam != null && !idsParam.trim().isEmpty()) {
        String[] parts = idsParam.split(",");
        for (String part : parts) {
            try {
                int val = Integer.parseInt(part.trim());
                if (!selectedIds.contains(val)) selectedIds.add(val);
            } catch (Exception ignore) {}
        }
    }

    if (orderIds != null) {
        for (String x : orderIds) {
            try {
                int val = Integer.parseInt(x.trim());
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

    StringBuilder idCsvBuilder = new StringBuilder();
    for (int i = 0; i < selectedIds.size(); i++) {
        if (i > 0) idCsvBuilder.append(",");
        idCsvBuilder.append(selectedIds.get(i));
    }
    String idCsv = idCsvBuilder.toString();

    double subtotal = 0.00;
    double postage = 0.00;
    double grandTotal = 0.00;
    int validOrderCount = 0;
    int addressCount = 0;
    String selectedRegion = "WEST";
    long refID = new java.util.Date().getTime();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>

<div class="container d-flex justify-content-center my-4">
    <div class="card shadow-sm payment-card">
        <div class="card-body p-4">

            <div class="text-center mb-4">
                <h2 class="brand-title">FitStyle</h2>
                <span class="badge" style="background-color:#043927; color:#D4AF37;">CHECKOUT REVIEW</span>
                <p class="text-muted small mt-2">Reference No.: #FS<%= refID %></p>
            </div>

            <%
                String msg = request.getParameter("msg");
                if ("payment_cancelled".equals(msg)) {
            %>
                <div class="alert alert-warning">
                    <i class="fas fa-circle-exclamation me-1"></i>
                    Payment was cancelled. Your order is still unpaid.
                </div>
            <% } else if ("payment_not_approved".equals(msg)) { %>
                <div class="alert alert-danger">
                    <i class="fas fa-lock me-1"></i>
                    Payment must be approved through the payment simulator before the order can be marked as paid.
                </div>
            <% } else if ("missing_payment_details".equals(msg)) { %>
                <div class="alert alert-danger">
                    Please choose a delivery address and payment method before proceeding.
                </div>
            <% } %>


            <hr style="border-top:1px dashed #ccc;">

            <h6 class="section-title mb-3">SELECTED ORDERS</h6>

            <%
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = fitstyle.util.DBConnection.getConnection();

                    StringBuilder placeholders = new StringBuilder();
                    for (int i = 0; i < selectedIds.size(); i++) {
                        if (i > 0) placeholders.append(",");
                        placeholders.append("?");
                    }

                    String sql = "SELECT o.order_id, o.design_id, o.shirt_fabric_name, o.skirt_fabric_name, "
                            + "o.total_price, o.top_size, o.bottom_size, o.fit_preference, "
                            + "o.height_cm, o.weight_kg, o.special_request, o.payment_status, o.order_status, "
                            + "o.decoration_name, o.decoration_area, o.decoration_notes, COALESCE(o.decoration_price,0) AS decoration_price, "
                            + "d.base_price, d.design_name "
                            + "FROM orders o LEFT JOIN designs d ON o.design_id = d.design_id "
                            + "WHERE o.customer_id=? AND o.order_id IN (" + placeholders.toString() + ") "
                            + "AND o.payment_status <> 'paid' "
                            + "AND (o.order_status IS NULL OR o.order_status <> 'cancelled') "
                            + "ORDER BY o.order_id DESC";

                    ps = conn.prepareStatement(sql);
                    ps.setInt(1, customerId);
                    for (int i = 0; i < selectedIds.size(); i++) {
                        ps.setInt(i + 2, selectedIds.get(i));
                    }

                    rs = ps.executeQuery();

                    while (rs.next()) {
                        validOrderCount++;
                        double orderTotal = rs.getDouble("total_price");
                        double base = rs.getDouble("base_price");
                        double decorationPrice = rs.getDouble("decoration_price");
                        double materialPrice = orderTotal - base - decorationPrice;
                        if (materialPrice < 0) materialPrice = 0.00;
                        subtotal += orderTotal;
            %>

            <div class="order-item">
                <div class="d-flex justify-content-between flex-wrap gap-2">
                    <div>
                        <div class="fw-bold" style="color:#043927;">
                            #FS-<%= rs.getInt("order_id") %> - <%= rs.getString("design_name") != null ? esc(rs.getString("design_name")) : "Design #" + rs.getInt("design_id") %>
                        </div>
                        <div class="small text-muted">Design ID: <%= rs.getInt("design_id") %></div>
                    </div>
                    <div class="fw-bold text-success">RM <%= String.format("%.2f", orderTotal) %></div>
                </div>

                <div class="row small mt-2">
                    <div class="col-md-6"><strong>Top Fabric:</strong> <%= rs.getString("shirt_fabric_name") != null ? esc(rs.getString("shirt_fabric_name")) : "-" %></div>
                    <div class="col-md-6"><strong>Bottom Fabric:</strong> <%= rs.getString("skirt_fabric_name") != null && !rs.getString("skirt_fabric_name").trim().isEmpty() ? esc(rs.getString("skirt_fabric_name")) : "Same as top / Not selected" %></div>
                    <div class="col-md-6"><strong>Top Size:</strong> <%= rs.getString("top_size") != null && !rs.getString("top_size").trim().isEmpty() ? esc(rs.getString("top_size")) : "-" %></div>
                    <div class="col-md-6"><strong>Bottom Size:</strong> <%= rs.getString("bottom_size") != null && !rs.getString("bottom_size").trim().isEmpty() ? esc(rs.getString("bottom_size")) : "-" %></div>
                    <div class="col-md-6"><strong>Sewing Cost:</strong> RM <%= String.format("%.2f", base) %></div>
                    <div class="col-md-6"><strong>Material Cost:</strong> RM <%= String.format("%.2f", materialPrice) %></div>
                    <div class="col-md-6"><strong>Decoration:</strong> <%= rs.getString("decoration_name") != null && !rs.getString("decoration_name").trim().isEmpty() ? esc(rs.getString("decoration_name")) + " (Placement: " + esc(rs.getString("decoration_area") != null ? rs.getString("decoration_area") : "-") + ")" : "No Decoration" %></div>
                    <div class="col-md-6"><strong>Decoration Cost:</strong> RM <%= String.format("%.2f", decorationPrice) %></div>
                    <div class="col-12"><strong>Special Request:</strong> <%= rs.getString("special_request") != null && !rs.getString("special_request").trim().isEmpty() ? esc(rs.getString("special_request")) : "-" %></div>
                </div>
            </div>

            <%
                    }
                    try { if (rs != null) rs.close(); } catch (Exception ignore) {}
                    try { if (ps != null) ps.close(); } catch (Exception ignore) {}

                    if (validOrderCount == 0) {
            %>
                <div class="alert alert-warning">No unpaid selected orders found. The order may already be paid or cancelled.</div>
                <a href="order-history.jsp" class="btn btn-secondary w-100 mt-2 fw-bold">Back to Order History</a>
            <%
                    } else {
            %>

            <form action="payment-simulator.jsp" method="POST" onsubmit="return confirmPayment();">
                <input type="hidden" name="ids" value="<%= idCsv %>">

                <h6 class="section-title mb-3 mt-4">DELIVERY ADDRESS</h6>
                <div class="alert alert-light border small">
                    <i class="fas fa-truck me-1"></i>
                    Shipping rate: <strong>Semenanjung Malaysia</strong> RM8 first item + RM3 each additional item. <strong>Sabah/Sarawak</strong> RM15 first item + RM5 each additional item.
                </div>

                <div class="row g-3">
                    <%
                        ps = conn.prepareStatement("SELECT * FROM customer_addresses WHERE customer_id=? ORDER BY is_default DESC, address_id DESC");
                        ps.setInt(1, customerId);
                        rs = ps.executeQuery();
                        boolean firstAddress = true;
                        while (rs.next()) {
                            addressCount++;
                            String region = rs.getString("region") == null ? "WEST" : rs.getString("region");
                            if (firstAddress) selectedRegion = region;
                            String checked = firstAddress ? "checked" : "";
                            firstAddress = false;
                    %>
                    <div class="col-md-6">
                        <label class="w-100 h-100">
                            <input class="address-radio" type="radio" name="addressId" value="<%= rs.getInt("address_id") %>" data-region="<%= esc(region) %>" <%= checked %> required onchange="updateShipping();">
                            <div class="address-card">
                                <div class="d-flex justify-content-between align-items-start gap-2">
                                    <div>
                                        <strong><%= esc(rs.getString("label")) %></strong>
                                        <% if (rs.getBoolean("is_default")) { %><span class="badge bg-success ms-1">Default</span><% } %>
                                    </div>
                                    <span class="badge badge-region"><%= regionDisplay(region) %></span>
                                </div>
                                <div class="small mt-2">
                                    <strong><%= esc(rs.getString("recipient_name")) %></strong><br>
                                    <%= esc(rs.getString("phone")) %><br>
                                    <%= esc(rs.getString("address_line1")) %><br>
                                    <% if (rs.getString("address_line2") != null && !rs.getString("address_line2").trim().isEmpty()) { %>
                                        <%= esc(rs.getString("address_line2")) %><br>
                                    <% } %>
                                    <%= esc(rs.getString("postcode")) %> <%= esc(rs.getString("city")) %>, <%= esc(rs.getString("state")) %>
                                </div>
                            </div>
                        </label>
                    </div>
                    <% } %>
                </div>

                <% if (addressCount == 0) { %>
                    <div class="alert alert-warning mt-3">
                        <i class="fas fa-map-marker-alt me-1"></i>
                        Please add a delivery address first before making payment.
                    </div>
                    <a href="address-book.jsp?returnTo=payment&ids=<%= idCsv %>" class="btn btn-success w-100 fw-bold">
                        <i class="fas fa-plus me-1"></i> Add Delivery Address
                    </a>
                    <a href="order-history.jsp" class="btn btn-outline-secondary w-100 mt-2 p-2 fw-bold">Back to Order History</a>
                <% } else {
                    postage = calcShipping(selectedRegion, validOrderCount);
                    grandTotal = subtotal + postage;
                %>

                <div class="d-flex justify-content-end mt-3">
                    <a href="address-book.jsp?returnTo=payment&ids=<%= idCsv %>" class="btn btn-outline-success btn-sm fw-bold">
                        <i class="fas fa-plus me-1"></i> Add / Manage Address
                    </a>
                </div>

                <div class="summary-box mt-4">
                    <h6 class="section-title mb-3">PRICE BREAKDOWN</h6>

                    <div class="d-flex justify-content-between">
                        <span>Orders Subtotal (<%= validOrderCount %> item<%= validOrderCount > 1 ? "s" : "" %>):</span>
                        <strong>RM <%= String.format("%.2f", subtotal) %></strong>
                    </div>

                    <div class="d-flex justify-content-between">
                        <span id="shippingLabel">Postage Fee (<%= regionDisplay(selectedRegion) %>):</span>
                        <strong id="shippingAmount">RM <%= String.format("%.2f", postage) %></strong>
                    </div>
                    <div class="small text-muted" id="shippingFormula"></div>

                    <hr>

                    <div class="d-flex justify-content-between align-items-center">
                        <span class="fw-bold">GRAND TOTAL:</span>
                        <h4 class="fw-bold mb-0" style="color:#043927;" id="grandTotalAmount">RM <%= String.format("%.2f", grandTotal) %></h4>
                    </div>
                </div>

                <div class="summary-box mt-4">
                    <h6 class="section-title mb-3">PAYMENT METHOD</h6>
                    <p class="small text-muted mb-3">
                        Choose a simulated payment method. No real transaction will be made.
                    </p>

                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="w-100">
                                <input type="radio" name="paymentMethod" value="FPX Online Banking" class="form-check-input me-2" required>
                                <span class="fw-bold"><i class="fas fa-building-columns me-1"></i> FPX Online Banking</span>
                            </label>
                        </div>
                        <div class="col-md-4">
                            <label class="w-100">
                                <input type="radio" name="paymentMethod" value="Debit/Credit Card" class="form-check-input me-2" required>
                                <span class="fw-bold"><i class="fas fa-credit-card me-1"></i> Debit/Credit Card</span>
                            </label>
                        </div>
                        <div class="col-md-4">
                            <label class="w-100">
                                <input type="radio" name="paymentMethod" value="QR Transfer" class="form-check-input me-2" required>
                                <span class="fw-bold"><i class="fas fa-qrcode me-1"></i> QR Transfer</span>
                            </label>
                        </div>
                    </div>
                </div>

                <button type="submit"
                   class="btn btn-warning w-100 mt-4 p-2 fw-bold shadow-sm"
                   style="background-color:#D4AF37; border:none; color:#043927;">
                    <i class="fas fa-shield-alt me-2"></i> PROCEED TO SECURE PAYMENT SIMULATION
                </button>

                <a href="order-history.jsp" class="btn btn-outline-secondary w-100 mt-2 p-2 fw-bold">
                    Back to Order History
                </a>

                <div class="alert alert-info small mt-3">
                    <i class="fas fa-info-circle"></i>
                    <strong>Info:</strong>
                    Selected orders will be confirmed together. Shipping is calculated based on the selected delivery address region and total number of outfits in this checkout.
                </div>
                <% } %>
            </form>

            <%
                    }
                } catch (Exception e) {
            %>
                <div class="alert alert-danger">Error: <%= e.getMessage() %><br><small>Please import the updated SQL file if this mentions <b>customer_addresses</b> or shipping columns.</small></div>
                <a href="order-history.jsp" class="btn btn-secondary w-100 mt-2 fw-bold">Back to Order History</a>
            <%
                } finally {
                    try { if (rs != null) rs.close(); } catch (Exception ignore) {}
                    try { if (ps != null) ps.close(); } catch (Exception ignore) {}
                    try { if (conn != null) conn.close(); } catch (Exception ignore) {}
                }
            %>

        </div>
    </div>
</div>

<script>
    const subtotal = <%= String.format(java.util.Locale.US, "%.2f", subtotal) %>;
    const itemCount = <%= validOrderCount %>;

    function formatMoney(amount) {
        return 'RM ' + amount.toFixed(2);
    }

    function calculateShipping(region) {
        if (itemCount <= 0) return 0;
        if (region === 'EAST') {
            return 15 + ((itemCount - 1) * 5);
        }
        return 8 + ((itemCount - 1) * 3);
    }

    function updateShipping() {
        const selected = document.querySelector('input[name="addressId"]:checked');
        if (!selected) return;
        const region = selected.dataset.region || 'WEST';
        const isEast = region === 'EAST';
        const shipping = calculateShipping(region);
        const regionText = isEast ? 'Sabah/Sarawak' : 'Semenanjung Malaysia';
        const formulaText = isEast
            ? 'RM15 first item + RM5 each additional item'
            : 'RM8 first item + RM3 each additional item';

        const shippingLabel = document.getElementById('shippingLabel');
        const shippingAmount = document.getElementById('shippingAmount');
        const shippingFormula = document.getElementById('shippingFormula');
        const grandTotalAmount = document.getElementById('grandTotalAmount');

        if (shippingLabel) shippingLabel.innerText = 'Postage Fee (' + regionText + '):';
        if (shippingAmount) shippingAmount.innerText = formatMoney(shipping);
        if (shippingFormula) shippingFormula.innerText = formulaText;
        if (grandTotalAmount) grandTotalAmount.innerText = formatMoney(subtotal + shipping);
    }

    function confirmPayment() {
        const selected = document.querySelector('input[name="addressId"]:checked');
        if (!selected) {
            alert('Please choose a delivery address first.');
            return false;
        }
        const method = document.querySelector('input[name="paymentMethod"]:checked');
        if (!method) {
            alert('Please choose a payment method first.');
            return false;
        }
        updateShipping();
        return confirm('Proceed to payment simulation for ' + itemCount + ' selected order(s)?');
    }

    document.addEventListener('DOMContentLoaded', updateShipping);
</script>

</body>
</html>
