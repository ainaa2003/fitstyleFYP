<%-- 
    Document   : order-form
    Created on : Jan 19, 2026, 2:20:33 AM
    Author     : Acer
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<!DOCTYPE html>
<%
    if (session.getAttribute("userEmail") == null) {
        response.sendRedirect("login.jsp?error=login_required");
        return;
    }

    if ("tailor".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("browse-designs.jsp?msg=tailor_preview_only");
        return;
    }

    Connection conn = null;
    Statement stmt = null;
    Statement stmtType = null;
    ResultSet rsMat = null;
    ResultSet rsType = null;
    ResultSet rsDec = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();

        // penting supaya boleh beforeFirst()
        stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
        stmtType = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);

        // 1) dropdown (TYPE)
        rsType = stmtType.executeQuery("SELECT DISTINCT material_type FROM materials ORDER BY material_type");

        // 2) list (NAME + PRICE + IMG) - ikut type
        rsMat = stmt.executeQuery(
                "SELECT material_type, material_name, image_name, extra_price, stock_quantity "
                + "FROM materials ORDER BY material_type, material_name"
        );

        String editOrderId = request.getParameter("editOrderId");
        boolean isEdit = (editOrderId != null && !editOrderId.trim().isEmpty());

        ResultSet rsOrder = null;

        String savedTopSize = "";
        String savedBottomSize = "";
        String savedFit = "";
        String savedHeight = "";
        String savedWeight = "";
        String savedNotes = "";
        String savedShirt = "";
        String savedSkirt = "";
        String savedDesignId = "";
        String savedBasePrice = "0";
        String savedTotalPrice = "0";
        String savedShirtType = "";
        String savedSkirtType = "";
        boolean savedSyncFabric = false;
        String savedShirtExtraMeter = "0";
        String savedSkirtExtraMeter = "0";
        String savedDecorationId = "0";
        String savedDecorationArea = "";
        String savedDecorationNotes = "";
        String sizeGuideType = "Baju Kurung Standard";
        String orderToken = "";
        if (!isEdit) {
            orderToken = java.util.UUID.randomUUID().toString();
            session.setAttribute("orderSubmitToken", orderToken);
        }

        if (isEdit) {
            PreparedStatement psEdit = conn.prepareStatement(
                    "SELECT o.*, d.base_price, "
                    + "COALESCE(o.shirt_fabric_type, m1.material_type) AS shirt_type, "
                    + "COALESCE(o.skirt_fabric_type, m2.material_type) AS skirt_type "
                    + "FROM orders o "
                    + "JOIN designs d ON o.design_id = d.design_id "
                    + "LEFT JOIN materials m1 ON o.shirt_fabric_name = m1.material_name "
                    + "LEFT JOIN materials m2 ON o.skirt_fabric_name = m2.material_name "
                    + "WHERE o.order_id=?"
            );
            psEdit.setInt(1, Integer.parseInt(editOrderId));
            rsOrder = psEdit.executeQuery();

            if (rsOrder.next()) {
                savedTopSize = rsOrder.getString("top_size");
                savedBottomSize = rsOrder.getString("bottom_size");
                savedFit = rsOrder.getString("fit_preference");
                savedHeight = rsOrder.getString("height_cm");
                savedWeight = rsOrder.getString("weight_kg");
                savedNotes = rsOrder.getString("special_request");
                savedShirt = rsOrder.getString("shirt_fabric_name");
                savedSkirt = rsOrder.getString("skirt_fabric_name");
                savedDesignId = rsOrder.getString("design_id");
                savedBasePrice = rsOrder.getString("base_price");
                savedTotalPrice = rsOrder.getString("total_price");
                savedShirtType = rsOrder.getString("shirt_type");
                savedSkirtType = rsOrder.getString("skirt_type");
                try { savedDecorationId = rsOrder.getString("decoration_id") != null ? rsOrder.getString("decoration_id") : "0"; } catch (Exception ignore) { savedDecorationId = "0"; }
                try { savedDecorationArea = rsOrder.getString("decoration_area") != null ? rsOrder.getString("decoration_area") : ""; } catch (Exception ignore) { savedDecorationArea = ""; }
                try { savedDecorationNotes = rsOrder.getString("decoration_notes") != null ? rsOrder.getString("decoration_notes") : ""; } catch (Exception ignore) { savedDecorationNotes = ""; }

                try {
                    double shirtMeterUsed = rsOrder.getDouble("shirt_meter_used");
                    double skirtMeterUsed = rsOrder.getDouble("skirt_meter_used");
                    savedShirtExtraMeter = String.format("%.0f", Math.max(0, shirtMeterUsed - 2));
                    savedSkirtExtraMeter = String.format("%.0f", Math.max(0, skirtMeterUsed - 2));
                } catch (Exception ignore) {
                    savedShirtExtraMeter = "0";
                    savedSkirtExtraMeter = "0";
                }

                // If customer used "Matching (Same as Top)", old data may have NULL bottom fabric
                // because disabled bottom fields are not submitted by browser. Show it back as matching.
                if (savedSkirt == null || savedSkirt.trim().isEmpty()) {
                    savedSkirt = savedShirt;
                    savedSkirtType = savedShirtType;
                    savedSyncFabric = true;
                } else if (savedShirt != null && savedShirt.equals(savedSkirt)) {
                    savedSyncFabric = true;
                }

                // For matching orders with duplicate material names, find the correct type using the saved price.
                if (savedSyncFabric && savedShirt != null && !savedShirt.trim().isEmpty()) {
                    try {
                        double targetExtra = (Double.parseDouble(savedTotalPrice) - Double.parseDouble(savedBasePrice)) / 2.0;
                        PreparedStatement psTypeFix = conn.prepareStatement(
                                "SELECT material_type FROM materials WHERE material_name=? AND ABS(extra_price - ?) < 0.01 LIMIT 1"
                        );
                        psTypeFix.setString(1, savedShirt);
                        psTypeFix.setDouble(2, targetExtra);
                        ResultSet rsTypeFix = psTypeFix.executeQuery();
                        if (rsTypeFix.next()) {
                            savedShirtType = rsTypeFix.getString("material_type");
                            savedSkirtType = savedShirtType;
                        }
                        rsTypeFix.close();
                        psTypeFix.close();
                    } catch (Exception ignore) {
                    }
                }
            }
        }

        String currentDesignId = isEdit ? savedDesignId : request.getParameter("designID");
        if (currentDesignId != null && !currentDesignId.trim().isEmpty()) {
            try {
                PreparedStatement psGuide = conn.prepareStatement(
                        "SELECT COALESCE(size_guide_type, 'Baju Kurung Standard') AS size_guide_type FROM designs WHERE design_id=?"
                );
                psGuide.setInt(1, Integer.parseInt(currentDesignId));
                ResultSet rsGuide = psGuide.executeQuery();
                if (rsGuide.next()) {
                    sizeGuideType = rsGuide.getString("size_guide_type");
                }
                rsGuide.close();
                psGuide.close();
            } catch (Exception ignore) {
                sizeGuideType = "Baju Kurung Standard";
            }
        }

        boolean isTopOnlyDesign = "Kurta".equalsIgnoreCase(sizeGuideType) || "Jubah".equalsIgnoreCase(sizeGuideType);
        try {
            PreparedStatement psDec = conn.prepareStatement("SELECT decoration_id, decoration_name, description, price, image_name, COALESCE(decoration_type, 'Other') AS decoration_type FROM decorations WHERE is_active=1 ORDER BY decoration_type, decoration_name");
            rsDec = psDec.executeQuery();
        } catch (Exception ignore) {
            rsDec = null;
        }

        if (isTopOnlyDesign) {
            savedSkirt = "";
            savedSkirtType = "";
            savedSyncFabric = false;
            savedSkirtExtraMeter = "0";
            savedBottomSize = "";
        }
%>

<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Form | FitStyle</title>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            body {
                font-family:'Poppins',sans-serif;
                background-color:#f4f7f6;
                color: var(--primary);
            }

            .order-card {
                border:none;
                box-shadow:0 10px 30px rgba(0,0,0,0.1);
                margin-top:40px;
                margin-bottom:50px;
            }

            .card-header {
                background-color:var(--primary);
                color:var(--gold);
                border-bottom:4px solid var(--gold);
                padding:25px;
                text-align:center;
            }

            .section-title {
                border-left:4px solid var(--gold);
                padding-left:10px;
                margin:30px 0 20px 0;
                color:var(--primary);
                font-weight:600;
                text-transform:uppercase;
            }

            .fabric-list {
                display:none;
            }

            .fabric-item {
                cursor:pointer;
                transition:.3s;
                border:2px solid #eee;
                padding:10px;
                text-align:center;
                background:white;
                position:relative;
            }

            /* bila dipilih */
            input[type="radio"]:checked + .fabric-item{
                border-color: var(--primary);
                box-shadow: 0 0 0 .2rem rgba(0,0,0,0.08);
            }

            /* tanda ✓ */
            input[type="radio"]:checked + .fabric-item::after{
                content:"✓";
                position:absolute;
                top:10px;
                right:10px;
                width:26px;
                height:26px;
                border-radius:50%;
                display:flex;
                align-items:center;
                justify-content:center;
                background:var(--primary);
                color:#fff;
                font-weight:700;
                font-size:14px;
            }

            .fabric-item img {
                width:100%;
                height:120px;
                object-fit:cover;
            }

            .decoration-card {
                border:2px solid #eee;
                border-radius:14px;
                background:#fff;
                padding:12px;
                height:100%;
                cursor:pointer;
                transition:.2s;
                position:relative;
            }

            .decoration-card img {
                width:100%;
                height:150px;
                object-fit:cover;
                border-radius:10px;
                border:1px solid #eee;
                background:#fafafa;
            }

            input[type="radio"]:checked + .decoration-card {
                border-color:var(--primary);
                box-shadow:0 0 0 .2rem rgba(0,0,0,0.08);
            }

            input[type="radio"]:checked + .decoration-card::after {
                content:"✓";
                position:absolute;
                top:12px;
                right:12px;
                width:28px;
                height:28px;
                border-radius:50%;
                display:flex;
                align-items:center;
                justify-content:center;
                background:var(--primary);
                color:#fff;
                font-weight:700;
            }

            .decoration-area-box {
                background:#f8f9fa;
                border:1px solid #e9ecef;
                border-radius:12px;
                padding:15px;
                margin-top:15px;
                display:none;
            }

            .decoration-filter {
                background:#fff;
                border:1px solid #e9ecef;
                border-radius:12px;
                padding:15px;
                margin-bottom:15px;
            }

            .placement-grid {
                display:grid;
                grid-template-columns:repeat(auto-fit, minmax(140px, 1fr));
                gap:10px;
            }

            .placement-option input {
                display:none;
            }

            .placement-option label {
                width:100%;
                border:2px solid #dee2e6;
                border-radius:12px;
                background:#fff;
                padding:12px 10px;
                text-align:center;
                cursor:pointer;
                font-weight:600;
                transition:.2s;
            }

            .placement-option input:checked + label {
                border-color:var(--primary);
                background:var(--primary);
                color:#fff;
            }

            .price-summary {
                background:var(--primary);
                color:white;
                padding:20px;
                border-radius:5px;
                margin-top:20px;
                border-bottom:5px solid var(--gold);
            }

            .price-val {
                font-size:1.5rem;
                font-weight:bold;
                color:var(--gold);
            }

            .btn-submit {
                background-color:var(--gold);
                color:var(--primary);
                border:none;
                padding:15px;
                font-weight:bold;
                width:100%;
                margin-top:20px;
            }

            .btn-submit:hover {
                background-color:#b8962d;
                color:white;
            }
            .measurement-guide-box{
                background:#fff;
                border:1px solid #e9ecef;
                border-radius:14px;
                padding:20px;
                margin-bottom:20px;
            }

            .measurement-guide-img{
                width:100%;
                max-height:520px;
                object-fit:contain;
                border-radius:10px;
                background:#fafafa;
                border:1px solid #eee;
                padding:10px;
            }

            .size-pick-group{
                display:grid;
                grid-template-columns:repeat(6, 1fr);
                gap:10px;
            }

            .size-option input{
                display:none;
            }

            .size-option label{
                width:100%;
                text-align:center;
                padding:14px 10px;
                border:2px solid #dee2e6;
                border-radius:10px;
                background:#fff;
                cursor:pointer;
                font-weight:600;
                transition:.2s;
            }

            .size-option input:checked + label{
                border-color:var(--primary);
                background:var(--primary);
                color:#fff;
            }

            .size-chart-table th{
                background:var(--primary);
                color:#fff;
                text-align:center;
                vertical-align:middle;
                font-size:.9rem;
            }

            .size-chart-table td{
                text-align:center;
                vertical-align:middle;
                font-size:.92rem;
            }

            .optional-note{
                font-size:.88rem;
                color:#6c757d;
            }

            .field-error {
                border-color: #dc3545 !important;
                box-shadow: 0 0 0 .15rem rgba(220, 53, 69, .12);
            }

            .fabric-item.unavailable {
                opacity: .55;
                cursor: not-allowed;
                background: #f8f9fa;
            }

            .fabric-stock-badge {
                position: absolute;
                top: 8px;
                left: 8px;
                font-size: .68rem;
            }

            .fabric-info-note {
                background: #fff8e1;
                border: 1px solid #ffe08a;
                color: #6b5300;
                border-radius: 10px;
                padding: 12px 14px;
                margin-bottom: 15px;
                font-size: .92rem;
            }

            @media (max-width: 768px){
                .size-pick-group{
                    grid-template-columns:repeat(3, 1fr);
                }
            }
        </style>
    </head>

    <body>
        <%@include file="includes/navbar.jsp" %>

        <div class="container">
            <div class="row justify-content-center">
                <div class="col-lg-10">
                    <div class="card order-card">
                        <div class="card-header">
                            <h3>Order & Price Calculation</h3>
                            <p class="text-white-50 mb-0">
                                Design ID: <%= isEdit ? savedDesignId : request.getParameter("designID")%>
                            </p>
                        </div>

                        <div class="card-body p-4 p-md-5">
                            <% if ("missing_required".equals(request.getParameter("msg"))) { %>
                            <div class="alert alert-danger" id="serverErrorBox">
                                <i class="fas fa-exclamation-circle me-1"></i>
                                Please complete all required order details before submitting.
                            </div>
                            <% } else if ("missing_bottom_material".equals(request.getParameter("msg"))) { %>
                            <div class="alert alert-danger" id="serverErrorBox">
                                <i class="fas fa-exclamation-circle me-1"></i>
                                Please choose a bottom material or tick "Matching (Same as Top)".
                            </div>
                            <% } else if ("insufficient_stock".equals(request.getParameter("msg"))) { %>
                            <div class="alert alert-danger" id="serverErrorBox">
                                <i class="fas fa-exclamation-circle me-1"></i>
                                The selected fabric stock is not enough. Please choose another material or reduce the additional fabric meter.
                            </div>
                            <% } %>

                            <div class="alert alert-danger d-none" id="orderValidationBox"></div>

                            <form action="OrderController" method="POST" onsubmit="return validateOrderForm();">
                                <input type="hidden" name="action" value="<%= isEdit ? "updateOrder" : "submitOrder"%>">
                                <% if (!isEdit) { %><input type="hidden" name="orderToken" value="<%= orderToken %>"><% } %>
                                <% if (isEdit) {%>
                                <input type="hidden" name="orderId" value="<%= editOrderId%>">
                                <% }%>
                                <input type="hidden" name="designID" value="<%= isEdit ? savedDesignId : request.getParameter("designID")%>">
                                <input type="hidden" name="basePrice" value="<%= isEdit ? savedBasePrice : request.getParameter("basePrice")%>">
                                <input type="hidden" id="totalPriceInput" name="totalPrice" value="">

                                <!-- 1) BAJU -->
                                <div class="section-title">1. CLOTHING PATTERN & MATERIAL</div>
                                <div class="fabric-info-note">
                                    <i class="fas fa-info-circle me-1"></i>
                                    Material price shown is for <strong>2 meters</strong> of fabric. If you need extra fabric for a larger size or loose fit, choose the additional meter option below. Extra fabric will increase the total price.
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Top Material Type</label>

                                        <select id="shirtFabricType" name="shirtFabricType" class="form-select" required onchange="filterFabric('shirt')">
                                            <option value="" data-key="">-- Choose Material --</option>
                                            <%
                                                rsType.beforeFirst();
                                                while (rsType.next()) {
                                                    String matType = rsType.getString("material_type");
                                                    String safeType = matType.replaceAll("\\s+", "_");
                                            %>
                                            <option value="<%= matType%>" data-key="<%= safeType%>"
                                                    <%= matType.equals(savedShirtType) ? "selected" : ""%>>
                                                <%= matType%>
                                            </option>
                                            <% } %>
                                        </select>
                                    </div>
                                </div>

                                <div id="shirtFabricContainer" class="row g-2 mb-4">
                                    <%
                                        rsMat.beforeFirst();
                                        while (rsMat.next()) {
                                            String matType = rsMat.getString("material_type");
                                            String matName = rsMat.getString("material_name");
                                            String safeType = matType.replaceAll("\\s+", "_");

                                            String imgName = rsMat.getString("image_name");
                                            String imgEncoded = java.net.URLEncoder.encode(imgName, "UTF-8");

                                            double extraPrice = rsMat.getDouble("extra_price");
                                            double stockQuantity = rsMat.getDouble("stock_quantity");
                                            boolean outOfStock = stockQuantity <= 0;
                                            boolean lowStock = stockQuantity > 0 && stockQuantity <= 2;
                                    %>

                                    <div class="fabric-list col-md-3 col-6"
                                         data-type="<%= safeType%>">

                                        <label class="w-100">
                                            <!-- letak data-price dekat radio supaya updatePrice boleh ambik -->
                                            <input type="radio"
                                                   name="shirtPattern"
                                                   value="<%= matName%>"
                                                   data-price="<%= extraPrice%>"
                                                   data-stock="<%= stockQuantity%>"
                                                   data-type-name="<%= matType%>"
                                                   class="d-none"
                                                   <%= matName.equals(savedShirt) && !outOfStock ? "checked" : ""%>
                                                   <%= outOfStock ? "disabled" : ""%>>

                                            <div class="fabric-item <%= outOfStock ? "unavailable" : ""%>">
                                                <% if (outOfStock) { %>
                                                    <span class="badge bg-secondary fabric-stock-badge">OUT OF STOCK</span>
                                                <% } else if (lowStock) { %>
                                                    <span class="badge bg-danger fabric-stock-badge">LOW STOCK</span>
                                                <% } %>
                                                <img src="displayImage?type=material&name=<%= imgEncoded%>"
                                                     onerror="this.src='https://via.placeholder.com/150?text=Fabric'">
                                                <div class="small mt-2">
                                                    <%= matName%> (2m: RM <%= String.format("%.2f", extraPrice)%>)
                                                </div>
                                                <div class="small text-muted">
                                                    Extra: RM <%= String.format("%.2f", extraPrice / 2)%> / meter<br>
                                                    Available: <%= String.format("%.2f", stockQuantity)%>m
                                                </div>
                                            </div>
                                        </label>
                                    </div>

                                    <% } %>
                                </div>

                                <div class="row mb-4">
                                    <div class="col-md-4">
                                        <label class="form-label fw-bold">Additional Top Fabric</label>
                                        <select id="shirtExtraMeter" name="shirtExtraMeter" class="form-select" onchange="updatePrice()">
                                            <option value="0" <%= "0".equals(savedShirtExtraMeter) ? "selected" : ""%>>0 meter</option>
                                            <option value="1" <%= "1".equals(savedShirtExtraMeter) ? "selected" : ""%>>+1 meter</option>
                                            <option value="2" <%= "2".equals(savedShirtExtraMeter) ? "selected" : ""%>>+2 meters</option>
                                        </select>
                                        <div class="small text-muted mt-1">Optional. Extra fabric is charged per meter.</div>
                                    </div>
                                </div>

                                <hr>

                                <% if (!isTopOnlyDesign) { %>
                                <!-- 2) KAIN -->
                                <div id="bottomFabricBlock">
                                <div class="section-title">2. FABRIC PATTERN (BOTTOM)</div>
                                <div class="form-check form-switch mb-3 p-3 bg-light border">
                                    <input class="form-check-input ms-0 me-2" type="checkbox" id="syncFabric" name="syncFabric" onchange="toggleSkirtSelection()" <%= savedSyncFabric ? "checked" : ""%>>
                                    <label class="form-check-label fw-bold" for="syncFabric">Matching (Same as Top)</label>
                                </div>

                                <div id="skirtSelectionArea">
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label fw-bold">Bottom Material Type</label>

                                            <select id="skirtFabricType" name="skirtFabricType" class="form-select" onchange="filterFabric('skirt')">
                                                <option value="" data-key="">-- Choose Material --</option>
                                                <%
                                                    rsType.beforeFirst();
                                                    while (rsType.next()) {
                                                        String matType = rsType.getString("material_type");
                                                        String safeType = matType.replaceAll("\\s+", "_");
                                                %>
                                                <option value="<%= matType%>" data-key="<%= safeType%>"
                                                        <%= matType.equals(savedSkirtType) ? "selected" : ""%>>
                                                    <%= matType%>
                                                </option>
                                                <%
                                                    }
                                                %>

                                            </select>
                                        </div>
                                    </div>

                                    <div id="skirtFabricContainer" class="row g-2 mb-4">
                                        <%
                                            rsMat.beforeFirst();
                                            while (rsMat.next()) {
                                                String matType = rsMat.getString("material_type");
                                                String matName = rsMat.getString("material_name");
                                                String safeType = matType.replaceAll("\\s+", "_");

                                                String imgName = rsMat.getString("image_name");
                                                String imgEncoded = java.net.URLEncoder.encode(imgName, "UTF-8");

                                                double extraPrice = rsMat.getDouble("extra_price");
                                            double stockQuantity = rsMat.getDouble("stock_quantity");
                                            boolean outOfStock = stockQuantity <= 0;
                                            boolean lowStock = stockQuantity > 0 && stockQuantity <= 2;
                                        %>

                                        <div class="fabric-list col-md-3 col-6"
                                             data-type="<%= safeType%>">

                                            <label class="w-100">
                                                <input type="radio"
                                                       name="skirtPattern"
                                                       value="<%= matName%>"
                                                       data-price="<%= extraPrice%>"
                                                       data-stock="<%= stockQuantity%>"
                                                       data-type-name="<%= matType%>"
                                                       class="d-none"
                                                       <%= matName.equals(savedSkirt) && !outOfStock ? "checked" : ""%>
                                                       <%= outOfStock ? "disabled" : ""%>>

                                                <div class="fabric-item <%= outOfStock ? "unavailable" : ""%>">
                                                    <% if (outOfStock) { %>
                                                        <span class="badge bg-secondary fabric-stock-badge">OUT OF STOCK</span>
                                                    <% } else if (lowStock) { %>
                                                        <span class="badge bg-danger fabric-stock-badge">LOW STOCK</span>
                                                    <% } %>
                                                    <img src="displayImage?type=material&name=<%= imgEncoded%>"
                                                         onerror="this.src='https://via.placeholder.com/150?text=Fabric'">
                                                    <div class="small mt-2">
                                                        <%= matName%> (2m: RM <%= String.format("%.2f", extraPrice)%>)
                                                    </div>
                                                    <div class="small text-muted">
                                                        Extra: RM <%= String.format("%.2f", extraPrice / 2)%> / meter<br>
                                                        Available: <%= String.format("%.2f", stockQuantity)%>m
                                                    </div>
                                                </div>
                                            </label>
                                        </div>

                                        <% }%>
                                    </div>
                                </div>

                                <div class="row mb-4">
                                    <div class="col-md-4">
                                        <label class="form-label fw-bold">Additional Bottom Fabric</label>
                                        <select id="skirtExtraMeter" name="skirtExtraMeter" class="form-select" onchange="updatePrice()">
                                            <option value="0" <%= "0".equals(savedSkirtExtraMeter) ? "selected" : ""%>>0 meter</option>
                                            <option value="1" <%= "1".equals(savedSkirtExtraMeter) ? "selected" : ""%>>+1 meter</option>
                                            <option value="2" <%= "2".equals(savedSkirtExtraMeter) ? "selected" : ""%>>+2 meters</option>
                                        </select>
                                        <div class="small text-muted mt-1">Optional. Bottom fabric also starts from 2 meters.</div>
                                    </div>
                                </div>
                                </div>
                                <% } else { %>
                                    <input type="hidden" name="skirtFabricType" id="skirtFabricType" value="">
                                    <input type="hidden" name="skirtPattern" value="">
                                    <input type="hidden" name="skirtExtraMeter" id="skirtExtraMeter" value="0">
                                <% } %>


                                <!-- 3) SIZE SELECTION -->
                                <div class="section-title">3. Select Size</div>
                                <p class="optional-note mb-3">
                                    Please choose your size based on our standard measurements. If you are unsure, we recommend choosing one size larger or leaving a note for the tailor.
                                </p>

                                <div class="measurement-guide-box">
                                    <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
                                        <div>
                                            <h5 class="fw-bold mb-1">Need help choosing your size?</h5>
                                            <div class="text-muted small">
                                                This order uses the <strong><%= sizeGuideType %></strong> size guide.
                                            </div>
                                        </div>
                                        <button type="button" class="btn btn-outline-success" data-bs-toggle="modal" data-bs-target="#sizeGuideModal">
                                            <i class="fas fa-ruler-combined me-1"></i> View Size Guide
                                        </button>
                                    </div>
                                </div>

                                <div class="modal fade" id="sizeGuideModal" tabindex="-1" aria-labelledby="sizeGuideModalLabel" aria-hidden="true">
                                    <div class="modal-dialog modal-xl modal-dialog-scrollable">
                                        <div class="modal-content">
                                            <div class="modal-header" style="background:#043927; color:#D4AF37;">
                                                <h5 class="modal-title" id="sizeGuideModalLabel"><%= sizeGuideType %> Size Guide</h5>
                                                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                                            </div>
                                            <div class="modal-body">
                                                <%
                                                    String guide = sizeGuideType != null ? sizeGuideType.trim() : "Baju Kurung Standard";
                                                    String guideImg = request.getContextPath() + "/image/baju-kurung-size-guide.png";
                                                    String guideAlt = "Baju Kurung Size Guide";
                                                    if ("Jubah".equalsIgnoreCase(guide)) {
                                                        guideImg = request.getContextPath() + "/image/jubah-size-guide.png";
                                                        guideAlt = "Jubah Size Guide";
                                                    } else if ("Baju Melayu".equalsIgnoreCase(guide)) {
                                                        guideImg = request.getContextPath() + "/image/baju-melayu-size-guide.png";
                                                        guideAlt = "Baju Melayu Size Guide";
                                                    } else if ("Kurta".equalsIgnoreCase(guide)) {
                                                        guideImg = request.getContextPath() + "/image/kurta-size-guide.png";
                                                        guideAlt = "Kurta Size Guide";
                                                    } else if ("Baju Kurung Kedah".equalsIgnoreCase(guide)) {
                                                        guideImg = request.getContextPath() + "/image/baju-kurung-kedah-size-guide.png";
                                                        guideAlt = "Baju Kurung Kedah Size Guide";
                                                    }
                                                %>

                                                <div class="row g-4">
                                                    <div class="col-lg-5">
                                                        <h6 class="fw-bold mb-2">How To Measure</h6>
                                                        <img src="<%= guideImg %>?v=4"
                                                             alt="<%= guideAlt %>"
                                                             class="measurement-guide-img"
                                                             onerror="this.onerror=null; this.src='<%= request.getContextPath()%>/image/baju-kurung-size-guide.png?v=4';">
                                                        <div class="small text-muted mt-2">
                                                            Use this guide before selecting your size. You may add notes for the tailor if your body measurement is between two sizes.
                                                        </div>
                                                    </div>

                                                    <div class="col-lg-7">
                                                        <h6 class="fw-bold mb-3">Size Chart (Inch)</h6>

                                                        <% if ("Jubah".equalsIgnoreCase(guide)) { %>
                                                        <div class="table-responsive">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Size</th>
                                                                        <th>Shoulder</th>
                                                                        <th>Bust / Chest</th>
                                                                        <th>Sleeve Length</th>
                                                                        <th>Jubah Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>13.5</td><td>34</td><td>21.5</td><td>52</td></tr>
                                                                    <tr><td>S</td><td>14</td><td>36</td><td>22</td><td>54</td></tr>
                                                                    <tr><td>M</td><td>14.5</td><td>38</td><td>22.5</td><td>56</td></tr>
                                                                    <tr><td>L</td><td>15</td><td>40</td><td>23</td><td>58</td></tr>
                                                                    <tr><td>XL</td><td>15.5</td><td>42</td><td>23.5</td><td>60</td></tr>
                                                                    <tr><td>XXL</td><td>16</td><td>44</td><td>24</td><td>62</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <% } else if ("Baju Melayu".equalsIgnoreCase(guide)) { %>
                                                        <div class="table-responsive mb-4">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Top Size</th>
                                                                        <th>Shoulder</th>
                                                                        <th>Chest</th>
                                                                        <th>Sleeve Length</th>
                                                                        <th>Shirt Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>15</td><td>36</td><td>22</td><td>27</td></tr>
                                                                    <tr><td>S</td><td>16</td><td>38</td><td>22.5</td><td>28</td></tr>
                                                                    <tr><td>M</td><td>17</td><td>40</td><td>23</td><td>29</td></tr>
                                                                    <tr><td>L</td><td>18</td><td>42</td><td>23.5</td><td>30</td></tr>
                                                                    <tr><td>XL</td><td>19</td><td>44</td><td>24</td><td>31</td></tr>
                                                                    <tr><td>XXL</td><td>20</td><td>46</td><td>24.5</td><td>32</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <div class="table-responsive">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Pants Size</th>
                                                                        <th>Waist</th>
                                                                        <th>Hip</th>
                                                                        <th>Pants Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>26</td><td>36</td><td>38</td></tr>
                                                                    <tr><td>S</td><td>28</td><td>38</td><td>39</td></tr>
                                                                    <tr><td>M</td><td>30</td><td>40</td><td>40</td></tr>
                                                                    <tr><td>L</td><td>32</td><td>42</td><td>41</td></tr>
                                                                    <tr><td>XL</td><td>34</td><td>44</td><td>42</td></tr>
                                                                    <tr><td>XXL</td><td>36</td><td>46</td><td>43</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <% } else if ("Kurta".equalsIgnoreCase(guide)) { %>
                                                        <div class="table-responsive">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Size</th>
                                                                        <th>Shoulder</th>
                                                                        <th>Chest</th>
                                                                        <th>Sleeve Length</th>
                                                                        <th>Kurta Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>15</td><td>36</td><td>21.5</td><td>35</td></tr>
                                                                    <tr><td>S</td><td>16</td><td>38</td><td>22</td><td>36</td></tr>
                                                                    <tr><td>M</td><td>17</td><td>40</td><td>22.5</td><td>37</td></tr>
                                                                    <tr><td>L</td><td>18</td><td>42</td><td>23</td><td>38</td></tr>
                                                                    <tr><td>XL</td><td>19</td><td>44</td><td>23.5</td><td>39</td></tr>
                                                                    <tr><td>XXL</td><td>20</td><td>46</td><td>24</td><td>40</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <% } else if ("Baju Kurung Kedah".equalsIgnoreCase(guide)) { %>
                                                        <div class="alert alert-info small">
                                                            Baju Kurung Kedah uses a shorter top length compared to standard Baju Kurung.
                                                        </div>
                                                        <div class="table-responsive mb-4">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Top Size</th>
                                                                        <th>Shoulder</th>
                                                                        <th>Bust / Chest</th>
                                                                        <th>Waist (Top)</th>
                                                                        <th>Sleeve Length</th>
                                                                        <th>Short Top Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>13.5</td><td>34</td><td>28</td><td>21.5</td><td>27</td></tr>
                                                                    <tr><td>S</td><td>14</td><td>36</td><td>30</td><td>22</td><td>28</td></tr>
                                                                    <tr><td>M</td><td>14.5</td><td>38</td><td>32</td><td>22.5</td><td>29</td></tr>
                                                                    <tr><td>L</td><td>15</td><td>40</td><td>34</td><td>23</td><td>30</td></tr>
                                                                    <tr><td>XL</td><td>15.5</td><td>42</td><td>36</td><td>23.5</td><td>31</td></tr>
                                                                    <tr><td>XXL</td><td>16</td><td>44</td><td>38</td><td>24</td><td>32</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <div class="table-responsive">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Skirt Size</th>
                                                                        <th>Waist (Skirt)</th>
                                                                        <th>Hip / Seat</th>
                                                                        <th>Skirt Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>24</td><td>36</td><td>39</td></tr>
                                                                    <tr><td>S</td><td>26</td><td>38</td><td>39.5</td></tr>
                                                                    <tr><td>M</td><td>28</td><td>40</td><td>40</td></tr>
                                                                    <tr><td>L</td><td>30</td><td>42</td><td>40.5</td></tr>
                                                                    <tr><td>XL</td><td>32</td><td>44</td><td>41</td></tr>
                                                                    <tr><td>XXL</td><td>34</td><td>46</td><td>41.5</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <% } else { %>
                                                        <div class="table-responsive mb-4">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Baju Kurung Size</th>
                                                                        <th>Shoulder</th>
                                                                        <th>Bust / Chest</th>
                                                                        <th>Waist (Top)</th>
                                                                        <th>Sleeve Length</th>
                                                                        <th>Baju Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>13.5</td><td>34</td><td>28</td><td>21.5</td><td>36</td></tr>
                                                                    <tr><td>S</td><td>14</td><td>36</td><td>30</td><td>22</td><td>37</td></tr>
                                                                    <tr><td>M</td><td>14.5</td><td>38</td><td>32</td><td>22.5</td><td>38</td></tr>
                                                                    <tr><td>L</td><td>15</td><td>40</td><td>34</td><td>23</td><td>39</td></tr>
                                                                    <tr><td>XL</td><td>15.5</td><td>42</td><td>36</td><td>23.5</td><td>40</td></tr>
                                                                    <tr><td>XXL</td><td>16</td><td>44</td><td>38</td><td>24</td><td>41</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>

                                                        <div class="table-responsive">
                                                            <table class="table table-bordered size-chart-table">
                                                                <thead>
                                                                    <tr>
                                                                        <th>Skirt Size</th>
                                                                        <th>Waist (Skirt)</th>
                                                                        <th>Hip / Seat</th>
                                                                        <th>Skirt Length</th>
                                                                    </tr>
                                                                </thead>
                                                                <tbody>
                                                                    <tr><td>XS</td><td>24</td><td>36</td><td>39</td></tr>
                                                                    <tr><td>S</td><td>26</td><td>38</td><td>39.5</td></tr>
                                                                    <tr><td>M</td><td>28</td><td>40</td><td>40</td></tr>
                                                                    <tr><td>L</td><td>30</td><td>42</td><td>40.5</td></tr>
                                                                    <tr><td>XL</td><td>32</td><td>44</td><td>41</td></tr>
                                                                    <tr><td>XXL</td><td>34</td><td>46</td><td>41.5</td></tr>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                        <% } %>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="col-md-6">
                                    <label class="form-label fw-bold">Select Top Size</label>
                                    <div class="size-pick-group">
                                        <div class="size-option">
                                            <input type="radio" id="topXS" name="topSize" value="XS" required <%= "XS".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topXS">XS</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="topS" name="topSize" value="S" <%= "S".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topS">S</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="topM" name="topSize" value="M" <%= "M".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topM">M</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="topL" name="topSize" value="L" <%= "L".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topL">L</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="topXL" name="topSize" value="XL" <%= "XL".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topXL">XL</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="topXXL" name="topSize" value="XXL" <%= "XXL".equals(savedTopSize) ? "checked" : ""%>>
                                            <label for="topXXL">XXL</label>
                                        </div>
                                    </div>
                                </div>

                                <% if (!isTopOnlyDesign) { %>
                                <div class="col-md-6">
                                    <label class="form-label fw-bold">Select Bottom Size</label>
                                    <div class="size-pick-group">
                                        <div class="size-option">
                                            <input type="radio" id="bottomXS" name="bottomSize" value="XS" required <%= "XS".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomXS">XS</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="bottomS" name="bottomSize" value="S" <%= "S".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomS">S</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="bottomM" name="bottomSize" value="M" <%= "M".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomM">M</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="bottomL" name="bottomSize" value="L" <%= "L".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomL">L</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="bottomXL" name="bottomSize" value="XL" <%= "XL".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomXL">XL</label>
                                        </div>
                                        <div class="size-option">
                                            <input type="radio" id="bottomXXL" name="bottomSize" value="XXL" <%= "XXL".equals(savedBottomSize) ? "checked" : ""%>>
                                            <label for="bottomXXL">XXL</label>
                                        </div>
                                    </div>
                                </div>
                                <% } else { %>
                                    <input type="hidden" name="bottomSize" value="">
                                    <div class="col-md-6">
                                        <div class="alert alert-info mb-0">
                                            <i class="fas fa-info-circle me-1"></i>
                                            <strong><%= sizeGuideType %></strong> uses top fabric and top size only. Bottom fabric and bottom size are not required.
                                        </div>
                                    </div>
                                <% } %>
                        </div>

                        <!-- 4) OPTIONAL DECORATION -->
                        <div class="section-title">4. Additional Decoration <span class="text-muted small">(Optional)</span></div>
                        <p class="optional-note mb-3">Choose one optional decoration if you want extra details such as beads, lace or embroidery. The price will be added to the total amount.</p>

                        <div class="decoration-filter">
                            <label class="form-label fw-bold">Decoration Type</label>
                            <select id="decorationTypeFilter" class="form-select" onchange="filterDecorationType()">
                                <option value="all">All Decoration Types</option>
                                <option value="Beads">Beads</option>
                                <option value="Lace">Lace</option>
                                <option value="Embroidery">Embroidery</option>
                                <option value="Ribbon">Ribbon</option>
                                <option value="Other">Other</option>
                            </select>
                            <div class="small text-muted mt-1">Filter decorations by type to make it easier to choose.</div>
                        </div>

                        <div class="row g-3 mb-3" id="decorationGallery">
                            <div class="col-md-3 col-sm-6 decoration-item" data-type="all">
                                <label class="w-100">
                                    <input type="radio" name="decorationId" value="0" data-price="0" class="d-none" onchange="updateDecorationArea(); updatePrice();" <%= "0".equals(savedDecorationId) || savedDecorationId == null || savedDecorationId.trim().isEmpty() ? "checked" : "" %>>
                                    <div class="decoration-card text-center">
                                        <div class="d-flex align-items-center justify-content-center bg-light rounded" style="height:150px; border:1px solid #eee;">
                                            <div>
                                                <i class="fas fa-ban fa-2x text-muted mb-2"></i><br>
                                                <strong>No Decoration</strong>
                                            </div>
                                        </div>
                                        <div class="fw-bold mt-2">No Decoration</div>
                                        <div class="small text-muted">No additional charge</div>
                                        <div class="fw-bold text-success mt-1">RM 0.00</div>
                                    </div>
                                </label>
                            </div>
                            <%
                                if (rsDec != null) {
                                    while (rsDec.next()) {
                                        String decId = rsDec.getString("decoration_id");
                                        String decName = rsDec.getString("decoration_name");
                                        String decDesc = rsDec.getString("description");
                                        double decPrice = rsDec.getDouble("price");
                                        String decImg = rsDec.getString("image_name");
                                        String decType = rsDec.getString("decoration_type") != null ? rsDec.getString("decoration_type") : "Other";
                            %>
                            <div class="col-md-3 col-sm-6 decoration-item" data-type="<%= decType %>">
                                <label class="w-100">
                                    <input type="radio" name="decorationId" value="<%= decId %>" data-price="<%= decPrice %>" class="d-none" onchange="updateDecorationArea(); updatePrice();" <%= decId.equals(savedDecorationId) ? "checked" : "" %>>
                                    <div class="decoration-card">
                                        <img src="displayImage?type=decoration&name=<%= java.net.URLEncoder.encode(decImg, "UTF-8") %>" alt="<%= decName %>" onerror="this.src='https://via.placeholder.com/300x180?text=Decoration'">
                                        <div class="fw-bold mt-2"><%= decName %></div>
                                        <span class="badge bg-light text-dark border"><%= decType %></span>
                                        <div class="small text-muted mt-1"><%= decDesc != null ? decDesc : "Optional decoration" %></div>
                                        <div class="fw-bold text-success mt-1">RM <%= String.format("%.2f", decPrice) %></div>
                                    </div>
                                </label>
                            </div>
                            <%
                                    }
                                }
                            %>
                        </div>

                        <div class="decoration-area-box" id="decorationAreaBox">
                            <label class="form-label fw-bold">Decoration Placement</label>
                            <div class="small text-muted mb-2">Choose where you want the decoration to be placed. You may select more than one area.</div>
                            <div class="placement-grid">
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decNeckline" value="Neckline" <%= savedDecorationArea != null && savedDecorationArea.contains("Neckline") ? "checked" : "" %>>
                                    <label for="decNeckline"><i class="fas fa-circle-dot me-1"></i> Neckline</label>
                                </div>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decChest" value="Chest / Front Body" <%= savedDecorationArea != null && savedDecorationArea.contains("Chest") ? "checked" : "" %>>
                                    <label for="decChest"><i class="fas fa-shirt me-1"></i> Chest / Front</label>
                                </div>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decSleeves" value="Sleeves" <%= savedDecorationArea != null && savedDecorationArea.contains("Sleeves") ? "checked" : "" %>>
                                    <label for="decSleeves"><i class="fas fa-hand-sparkles me-1"></i> Sleeves</label>
                                </div>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decCuffs" value="Cuffs / Wrist" <%= savedDecorationArea != null && (savedDecorationArea.contains("Cuffs") || savedDecorationArea.contains("Wrist")) ? "checked" : "" %>>
                                    <label for="decCuffs"><i class="fas fa-grip-lines me-1"></i> Cuffs / Wrist</label>
                                </div>
                                <% if (!isTopOnlyDesign) { %>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decSkirt" value="Skirt / Pants" <%= savedDecorationArea != null && (savedDecorationArea.contains("Skirt") || savedDecorationArea.contains("Pants")) ? "checked" : "" %>>
                                    <label for="decSkirt"><i class="fas fa-grip-lines-vertical me-1"></i> Skirt / Pants</label>
                                </div>
                                <% } %>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decHem" value="Hem / Bottom" <%= savedDecorationArea != null && (savedDecorationArea.contains("Hem") || savedDecorationArea.contains("Bottom")) ? "checked" : "" %>>
                                    <label for="decHem"><i class="fas fa-align-justify me-1"></i> Hem / Bottom</label>
                                </div>
                                <div class="placement-option">
                                    <input type="checkbox" name="decorationArea" id="decFull" value="Entire Outfit" <%= savedDecorationArea != null && savedDecorationArea.contains("Entire Outfit") ? "checked" : "" %>>
                                    <label for="decFull"><i class="fas fa-star me-1"></i> Entire Outfit</label>
                                </div>
                            </div>
                            <div class="mt-3">
                                <label class="form-label fw-bold">Decoration Notes <span class="text-muted small">(Optional)</span></label>
                                <textarea name="decorationNotes" id="decorationNotes" class="form-control" rows="3" placeholder="Example: Please make the beads denser on the neckline and lighter on the sleeves."><%= savedDecorationNotes != null ? savedDecorationNotes : "" %></textarea>
                                <div class="small text-muted mt-1">This note will be shown to the tailor for sewing reference.</div>
                            </div>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-3 col-sm-6">
                                <label class="w-100">
                                    <input type="radio" name="decorationId" value="0" data-price="0" class="d-none" onchange="updateDecorationArea(); updatePrice();" <%= "0".equals(savedDecorationId) || savedDecorationId == null || savedDecorationId.trim().isEmpty() ? "checked" : "" %>>
                                    <div class="decoration-card text-center">
                                        <div class="d-flex align-items-center justify-content-center bg-light rounded" style="height:150px; border:1px solid #eee;">
                                            <div>
                                                <i class="fas fa-ban fa-2x text-muted mb-2"></i><br>
                                                <strong>No Decoration</strong>
                                            </div>
                                        </div>
                                        <div class="fw-bold mt-2">No Decoration</div>
                                        <div class="small text-muted">No additional charge</div>
                                        <div class="fw-bold text-success mt-1">RM 0.00</div>
                                    </div>
                                </label>
                            </div>
                            <%
                                if (rsDec != null) {
                                    while (rsDec.next()) {
                                        String decId = rsDec.getString("decoration_id");
                                        String decName = rsDec.getString("decoration_name");
                                        String decDesc = rsDec.getString("description");
                                        double decPrice = rsDec.getDouble("price");
                                        String decImg = rsDec.getString("image_name");
                            %>
                            <div class="col-md-3 col-sm-6">
                                <label class="w-100">
                                    <input type="radio" name="decorationId" value="<%= decId %>" data-price="<%= decPrice %>" class="d-none" onchange="updateDecorationArea(); updatePrice();" <%= decId.equals(savedDecorationId) ? "checked" : "" %>>
                                    <div class="decoration-card">
                                        <img src="displayImage?type=decoration&name=<%= java.net.URLEncoder.encode(decImg, "UTF-8") %>" alt="<%= decName %>" onerror="this.src='https://via.placeholder.com/300x180?text=Decoration'">
                                        <div class="fw-bold mt-2"><%= decName %></div>
                                        <div class="small text-muted"><%= decDesc != null ? decDesc : "Optional decoration" %></div>
                                        <div class="fw-bold text-success mt-1">RM <%= String.format("%.2f", decPrice) %></div>
                                    </div>
                                </label>
                            </div>
                            <%
                                    }
                                }
                            %>
                        </div>

                        <div class="decoration-area-box" id="decorationAreaBox">
                            <label class="form-label fw-bold">Decoration Area</label>
                            <select name="decorationArea" id="decorationArea" class="form-select" onchange="updatePrice()">
                                <option value="">-- Choose Area --</option>
                                <option value="Neckline" <%= "Neckline".equals(savedDecorationArea) ? "selected" : "" %>>Neckline</option>
                                <option value="Sleeves" <%= "Sleeves".equals(savedDecorationArea) ? "selected" : "" %>>Sleeves</option>
                                <option value="Wrist" <%= "Wrist".equals(savedDecorationArea) ? "selected" : "" %>>Wrist</option>
                                <option value="Skirt" <%= "Skirt".equals(savedDecorationArea) ? "selected" : "" %>>Skirt</option>
                                <option value="Full Set" <%= "Full Set".equals(savedDecorationArea) ? "selected" : "" %>>Full Set</option>
                            </select>
                            <div class="small text-muted mt-1">Tailor will follow this selected decoration area when preparing the order.</div>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-4">
                                <label class="form-label fw-bold">Fit Preference <span class="text-muted small">(Optional)</span></label>
                                <select name="fitPreference" class="form-select">
                                    <option value="">-- Select Fit Preference --</option>
                                    <option value="Slim Fit" <%= "Slim Fit".equals(savedFit) ? "selected" : ""%>>Slim Fit</option>
                                    <option value="Regular Fit" <%= "Regular Fit".equals(savedFit) ? "selected" : ""%>>Regular Fit</option>
                                    <option value="Loose Fit" <%= "Loose Fit".equals(savedFit) ? "selected" : ""%>>Loose Fit</option>
                                </select>
                            </div>

                            <div class="col-md-4">
                                <label class="form-label fw-bold">Height (cm) <span class="text-muted small">(Optional)</span></label>
                                <input type="number" step="0.1" name="heightCm" class="form-control" placeholder="e.g. 160"
                                       value="<%= savedHeight != null ? savedHeight : ""%>">
                            </div>

                            <div class="col-md-4">
                                <label class="form-label fw-bold">Weight (kg) <span class="text-muted small">(Optional)</span></label>
                                <input type="number" step="0.1" name="weightKg" class="form-control" placeholder="e.g. 55"
                                       value="<%= savedWeight != null ? savedWeight : ""%>">
                            </div>

                            <div class="col-md-12">
                                <label class="form-label fw-bold">Special Request / Notes <span class="text-muted small">(Optional)</span></label>
                                <textarea name="specialRequest" rows="3" class="form-control" placeholder="Example: prefer slightly looser sleeves, longer top length, etc."><%= savedNotes != null ? savedNotes : ""%></textarea>
                            </div>
                        </div>
                        <!-- Summary -->
                        <div class="price-summary">
                            <div class="row align-items-center text-center">
                                <div class="col-md-4">Sewing Wages: <br><strong>RM <%= isEdit ? savedBasePrice : request.getParameter("basePrice")%></strong></div>
                                <div class="col-md-4">Material Cost: <br><strong id="displayFabricPrice">RM 0.00</strong><br><small id="displayMeterUsed" class="text-white-50"></small><br><small class="text-white-50">Decoration: <span id="displayDecorationPrice">RM 0.00</span></small></div>
                                <div class="col-md-4 border-start">TOTAL AMOUNT: <br><span class="price-val" id="displayTotalPrice">RM 0.00</span></div>
                            </div>
                        </div>

                        <button type="submit" class="btn-submit">
                            <%= isEdit ? "Update Order" : "Confirm & Submit Order" %> <i class="fas fa-paper-plane"></i>
                        </button>
                        </form>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        const UPAH_JAHIT = parseFloat("<%= isEdit ? savedBasePrice : request.getParameter("basePrice")%>") || 0;
        const TOP_ONLY_DESIGN = <%= isTopOnlyDesign ? "true" : "false" %>;


        function showOrderError(messages, firstElement) {
            const box = document.getElementById('orderValidationBox');
            box.classList.remove('d-none');
            box.innerHTML = '<strong>Please complete the required fields:</strong><ul class="mb-0 mt-2"><li>' + messages.join('</li><li>') + '</li></ul>';

            if (firstElement) {
                firstElement.scrollIntoView({behavior: 'smooth', block: 'center'});
                firstElement.classList.add('field-error');
                setTimeout(function () {
                    firstElement.classList.remove('field-error');
                }, 2500);
            }
        }

        function validateOrderForm() {
            const messages = [];
            let firstElement = null;

            function markMissing(el, message) {
                messages.push(message);
                if (!firstElement && el) {
                    firstElement = el;
                }
                if (el) {
                    el.classList.add('field-error');
                }
            }

            document.querySelectorAll('.field-error').forEach(function (el) {
                el.classList.remove('field-error');
            });

            const shirtType = document.getElementById('shirtFabricType');
            const shirtPattern = document.querySelector('input[name="shirtPattern"]:checked');
            const syncFabricEl = document.getElementById('syncFabric');
            const syncFabric = syncFabricEl ? syncFabricEl.checked : false;
            const skirtType = document.getElementById('skirtFabricType');
            const skirtPattern = document.querySelector('input[name="skirtPattern"]:checked');
            const topSize = document.querySelector('input[name="topSize"]:checked');
            const bottomSize = document.querySelector('input[name="bottomSize"]:checked');

            if (!shirtType.value) {
                markMissing(shirtType, 'Top Material Type');
            }
            if (!shirtPattern) {
                markMissing(document.getElementById('shirtFabricContainer'), 'Top Fabric Pattern');
            }
            if (!TOP_ONLY_DESIGN && !syncFabric) {
                if (!skirtType || !skirtType.value) {
                    markMissing(skirtType, 'Bottom Material Type');
                }
                if (!skirtPattern) {
                    markMissing(document.getElementById('skirtFabricContainer'), 'Bottom Fabric Pattern');
                }
            }
            if (!topSize) {
                markMissing(document.querySelector('input[name="topSize"]'), 'Top Size');
            }
            const decRadio = document.querySelector('input[name="decorationId"]:checked');
            const decAreaChecked = document.querySelectorAll('input[name="decorationArea"]:checked');
            const decAreaBox = document.getElementById('decorationAreaBox');
            if (decRadio && decRadio.value !== "0" && decAreaChecked.length === 0) {
                markMissing(decAreaBox, 'Decoration Placement');
            }
            if (!TOP_ONLY_DESIGN && !bottomSize) {
                markMissing(document.querySelector('input[name="bottomSize"]'), 'Bottom Size');
            }

            const shirtExtra = parseFloat(document.getElementById('shirtExtraMeter').value || "0");
            const skirtExtraEl = document.getElementById('skirtExtraMeter');
            const skirtExtra = TOP_ONLY_DESIGN ? 0 : parseFloat((skirtExtraEl ? skirtExtraEl.value : "0") || "0");
            if (shirtPattern) {
                const needed = 2 + shirtExtra;
                const available = parseFloat(shirtPattern.dataset.stock || "0");
                if (needed > available) {
                    markMissing(document.getElementById('shirtFabricContainer'), 'Top fabric stock is not enough. Needed ' + needed + 'm, available ' + available + 'm.');
                }
            }
            if (!TOP_ONLY_DESIGN && shirtPattern && syncFabric) {
                const needed = (2 + shirtExtra) + (2 + skirtExtra);
                const available = parseFloat(shirtPattern.dataset.stock || "0");
                if (needed > available) {
                    markMissing(document.getElementById('shirtFabricContainer'), 'Matching fabric stock is not enough. Needed ' + needed + 'm, available ' + available + 'm.');
                }
            } else if (!TOP_ONLY_DESIGN && !syncFabric && skirtPattern) {
                const needed = 2 + skirtExtra;
                const available = parseFloat(skirtPattern.dataset.stock || "0");
                if (needed > available) {
                    markMissing(document.getElementById('skirtFabricContainer'), 'Bottom fabric stock is not enough. Needed ' + needed + 'm, available ' + available + 'm.');
                }
            }

            if (messages.length > 0) {
                showOrderError(messages, firstElement);
                return false;
            }

            return true;
        }

        function updatePrice() {
            const syncFabricEl = document.getElementById('syncFabric');
            const isSynced = !TOP_ONLY_DESIGN && syncFabricEl && syncFabricEl.checked;

            const shirtRadio = document.querySelector('input[name="shirtPattern"]:checked');
            const skirtRadio = document.querySelector('input[name="skirtPattern"]:checked');

            const shirtExtra = parseFloat(document.getElementById('shirtExtraMeter').value || "0");
            const skirtExtraEl = document.getElementById('skirtExtraMeter');
            const skirtExtra = TOP_ONLY_DESIGN ? 0 : parseFloat((skirtExtraEl ? skirtExtraEl.value : "0") || "0");

            let shirtPrice2m = shirtRadio ? parseFloat(shirtRadio.dataset.price || "0") : 0;
            let skirtPrice2m = TOP_ONLY_DESIGN ? 0 : (isSynced ? shirtPrice2m : (skirtRadio ? parseFloat(skirtRadio.dataset.price || "0") : 0));

            let shirtPricePerMeter = shirtPrice2m / 2;
            let skirtPricePerMeter = skirtPrice2m / 2;

            let shirtCost = shirtRadio ? (shirtPrice2m + (shirtExtra * shirtPricePerMeter)) : 0;
            let skirtCost = (!TOP_ONLY_DESIGN && (isSynced || skirtRadio)) ? (skirtPrice2m + (skirtExtra * skirtPricePerMeter)) : 0;

            const totalFabric = shirtCost + skirtCost;
            const decorationRadio = document.querySelector('input[name="decorationId"]:checked');
            const decorationPrice = decorationRadio ? parseFloat(decorationRadio.dataset.price || "0") : 0;
            const grandTotal = UPAH_JAHIT + totalFabric + decorationPrice;

            const shirtMeters = shirtRadio ? (2 + shirtExtra) : 0;
            const skirtMeters = (!TOP_ONLY_DESIGN && (isSynced || skirtRadio)) ? (2 + skirtExtra) : 0;

            document.getElementById('displayFabricPrice').innerText = "RM " + totalFabric.toFixed(2);
            const decDisplay = document.getElementById('displayDecorationPrice');
            if (decDisplay) decDisplay.innerText = "RM " + decorationPrice.toFixed(2);
            document.getElementById('displayMeterUsed').innerText = TOP_ONLY_DESIGN ? ("Fabric used: Top " + shirtMeters.toFixed(0) + "m") : ("Fabric used: Top " + shirtMeters.toFixed(0) + "m + Bottom " + skirtMeters.toFixed(0) + "m");
            document.getElementById('displayTotalPrice').innerText = "RM " + grandTotal.toFixed(2);
            document.getElementById('totalPriceInput').value = grandTotal.toFixed(2);
        }

        function updateDecorationArea() {
            const selected = document.querySelector('input[name="decorationId"]:checked');
            const box = document.getElementById('decorationAreaBox');
            const areas = document.querySelectorAll('input[name="decorationArea"]');
            const notes = document.getElementById('decorationNotes');
            const hasDecoration = selected && selected.value !== "0";
            if (box) box.style.display = hasDecoration ? 'block' : 'none';
            areas.forEach(function(area) {
                if (!hasDecoration) area.checked = false;
            });
            if (!hasDecoration && notes) notes.value = '';
        }

        function filterDecorationType() {
            const selectedType = document.getElementById('decorationTypeFilter').value;
            document.querySelectorAll('.decoration-item').forEach(function(item) {
                const itemType = item.dataset.type || 'Other';
                item.style.display = (selectedType === 'all' || itemType === 'all' || itemType === selectedType) ? 'block' : 'none';
            });
        }

        function filterFabric(type) {
            const select = document.getElementById(type + 'FabricType');
            const container = document.getElementById(type + 'FabricContainer');
            if (!select || !container) {
                updatePrice();
                return;
            }

            container.querySelectorAll('.fabric-list').forEach(el => el.style.display = 'none');

            if (select.value) {
                const key = select.selectedOptions[0].dataset.key;
                const list = container.querySelectorAll('.fabric-list[data-type="' + key + '"]');
                list.forEach(el => el.style.display = 'block');

                const checkedRadio = container.querySelector('input[name="' + type + 'Pattern"]:checked');

                if (!checkedRadio && list.length > 0) {
                    let firstRadio = null;
                    for (let i = 0; i < list.length; i++) {
                        const candidate = list[i].querySelector('input[type="radio"]:not(:disabled)');
                        if (candidate) {
                            firstRadio = candidate;
                            break;
                        }
                    }
                    if (firstRadio) {
                        firstRadio.checked = true;
                    }
                }
            }

            updatePrice();
        }

        function toggleSkirtSelection() {
            const area = document.getElementById('skirtSelectionArea');
            const syncFabricEl = document.getElementById('syncFabric');
            const isSynced = !TOP_ONLY_DESIGN && syncFabricEl && syncFabricEl.checked;

            area.style.opacity = isSynced ? '0.3' : '1';
            area.style.pointerEvents = isSynced ? 'none' : 'auto';
            area.querySelectorAll('input, select').forEach(el => el.disabled = isSynced);

            updatePrice();
        }

        document.addEventListener('change', function (e) {
            if (e.target.type === 'radio')
                updatePrice();
        });

        document.addEventListener("DOMContentLoaded", function () {
            updateDecorationArea();
            const shirtChecked = document.querySelector('input[name="shirtPattern"]:checked');
            if (shirtChecked) {
                const shirtCard = shirtChecked.closest('.fabric-list');
                if (shirtCard) {
                    const shirtTypeKey = shirtCard.dataset.type;
                    const shirtSelect = document.getElementById('shirtFabricType');
                    const shirtOption = shirtSelect.querySelector('option[data-key="' + shirtTypeKey + '"]');
                    if (shirtOption) {
                        shirtSelect.value = shirtOption.value;
                    }
                }
            }

            const skirtChecked = document.querySelector('input[name="skirtPattern"]:checked');
            if (skirtChecked) {
                const skirtCard = skirtChecked.closest('.fabric-list');
                if (skirtCard) {
                    const skirtTypeKey = skirtCard.dataset.type;
                    const skirtSelect = document.getElementById('skirtFabricType');
                    const skirtOption = skirtSelect.querySelector('option[data-key="' + skirtTypeKey + '"]');
                    if (skirtOption) {
                        skirtSelect.value = skirtOption.value;
                    }
                }
            }

            if (document.getElementById('shirtFabricType') && document.getElementById('shirtFabricType').value) {
                filterFabric('shirt');
            }
            if (!TOP_ONLY_DESIGN && document.getElementById('skirtFabricType') && document.getElementById('skirtFabricType').value) {
                filterFabric('skirt');
            }

            if (!TOP_ONLY_DESIGN && shirtChecked && skirtChecked && shirtChecked.value === skirtChecked.value && document.getElementById('syncFabric')) {
                document.getElementById('syncFabric').checked = true;
                toggleSkirtSelection();
            }

            updatePrice();
        });
    </script>

</body>
</html>

<%
    } catch (Exception e) {
        out.println("Error: " + e.getMessage());
    } finally {
        try {
            if (rsType != null) {
                rsType.close();
            }
        } catch (Exception ignore) {
        }
        try {
            if (stmtType != null) {
                stmtType.close();
            }
        } catch (Exception ignore) {
        }
        try {
            if (rsMat != null) {
                rsMat.close();
            }
            if (rsDec != null) {
                rsDec.close();
            }
        } catch (Exception ignore) {
        }
        try {
            if (stmt != null) {
                stmt.close();
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
