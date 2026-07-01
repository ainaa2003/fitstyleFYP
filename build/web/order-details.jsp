<%-- 
    Document   : order-details
    Created on : Jan 19, 2026, 6:28:17 PM
    Author     : Acer
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<!DOCTYPE html>
<html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Order Details | FitStyle</title>
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            .card-custom {
                border-radius:15px;
                border:none;
                box-shadow:0 5px 15px rgba(0,0,0,0.1);
            }

            .header-section {
                background:var(--primary);
                color:white;
                padding:20px;
                border-radius:15px 15px 0 0;
            }

            .fabric-item{
                border:2px solid #eee;
                border-radius:10px;
                padding:10px;
                text-align:center;
                cursor:pointer;
                transition:all .3s ease;
                background:white;
                position:relative;
            }

            /* highlight card when radio checked */
            label input[type="radio"]:checked + .fabric-item{
                border-color: var(--primary);
                box-shadow: 0 0 0 .2rem rgba(4,57,39,.12);
            }

            /* selected check icon */
            label input[type="radio"]:checked + .fabric-item::after{
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
                border-radius:8px;
            }

            .fabric-item .small {
                font-weight:bold;
                margin-top:8px;
                display:block;
                color: var(--primary);
            }

            .fabric-list {
                display:none;
            }

            .section-title {
                font-weight:700;
                margin-top:15px;
                color: var(--primary);
            }
        </style>
    </head>

    <body class="bg-light">
        <%@include file="includes/navbar.jsp" %>

        <%
            if ("tailor".equals(session.getAttribute("userRole"))) {
                response.sendRedirect("tailor-dashboard.jsp?section=dashboard&msg=Tailor cannot place customer orders.");
                return;
            }
        %>

        <div class="container my-5">
            <div class="row justify-content-center">
                <div class="col-md-10 col-lg-9">
                    <div class="card card-custom">

                        <%
                            String id = request.getParameter("id");

                            Connection conn = null;
                            PreparedStatement psOrder = null;
                            ResultSet rsOrder = null;

                            Statement stmtMat = null;
                            Statement stmtType = null;
                            ResultSet rsMat = null;
                            ResultSet rsType = null;

                            try {
                                Class.forName("com.mysql.cj.jdbc.Driver");
                                conn = fitstyle.util.DBConnection.getConnection();

                                // ===== 1) Get order =====
                                String sqlOrder = "SELECT * FROM orders WHERE order_id = ?";
                                psOrder = conn.prepareStatement(sqlOrder);
                                psOrder.setString(1, id);
                                rsOrder = psOrder.executeQuery();

                                if (!rsOrder.next()) {
                        %>
                        <div class="p-5 text-center">
                            <h5>Record not found.</h5>
                        </div>
                        <%
                        } else {
                            String status = rsOrder.getString("order_status");

                            // Only measurements can be edited while waiting for payment
                            boolean bolehEdit = "waiting_for_payment".equals(status);

                            String badgeClass = "bg-secondary";
                            if ("waiting_for_payment".equals(status)) {
                                badgeClass = "bg-warning text-dark";
                            } else if ("payment_confirmed".equals(status)) {
                                badgeClass = "bg-info text-dark";
                            } else if ("in_progress".equals(status)) {
                                badgeClass = "bg-primary text-white";
                            } else if ("ready_for_pickup".equals(status)) {
                                badgeClass = "bg-success text-white";
                            } else if ("completed".equals(status)) {
                                badgeClass = "bg-dark text-white";
                            } else if ("cancelled".equals(status)) {
                                badgeClass = "bg-danger text-white";
                            }

                            // ===== 2) Get materials (NEW system) =====
                            stmtMat = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);
                            stmtType = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_READ_ONLY);

                            rsType = stmtType.executeQuery("SELECT DISTINCT material_type FROM materials ORDER BY material_type");
                            rsMat = stmtMat.executeQuery("SELECT material_type, material_name, image_name, extra_price FROM materials ORDER BY material_type, material_name");

                            // Original selected values
                            String selectedShirtMat = rsOrder.getString("shirt_fabric_name");
                            String selectedSkirtMat = rsOrder.getString("skirt_fabric_name");
                        %>

                        <div class="header-section text-center">
                            <h4 class="mb-2">Order Details #FS-<%= id%></h4>
                            <span class="badge <%= badgeClass%>" style="font-size:0.9rem; padding:8px 15px;">
                                <i class="fas fa-info-circle me-1"></i>
                                <%= status.replace("_", " ").toUpperCase()%>
                            </span>
                        </div>

                        <div class="card-body p-4">
                            <form action="OrderController" method="POST">
                                <input type="hidden" name="action" value="updateOrder">
                                <input type="hidden" name="orderId" value="<%= id%>">

                                <!-- ===== MATERIAL (VIEW ONLY) ===== -->
                                <h6 class="fw-bold border-bottom pb-2 mb-3 text-uppercase">
                                    <i class="fas fa-layer-group me-2"></i>1. SHIRT PATTERN & MATERIAL
                                </h6>

                                <!-- Type dropdown (view only) -->
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label fw-bold">Top Material Type</label>
                                        <select id="shirtFabricType" class="form-select" onchange="filterFabric('shirt')" <%= bolehEdit ? "" : "disabled"%>>
                                            <option value="" data-key="">-- Select Material --</option>
                                            <%
                                                rsType.beforeFirst();
                                                while (rsType.next()) {
                                                    String matType = rsType.getString("material_type");
                                                    String safeType = matType == null ? "" : matType.trim().replaceAll("\\s+", "_");
                                            %>
                                            <option value="<%= matType%>" data-key="<%= safeType%>"><%= matType%></option>
                                            <% } %>
                                        </select>                              
                                    </div>
                                </div>

                                <!-- Top fabric cards (view only) -->
                                <div id="shirtFabricContainer" class="row g-2 mb-4">
                                    <%
                                        rsMat.beforeFirst();
                                        while (rsMat.next()) {
                                            String matType = rsMat.getString("material_type");
                                            String matName = rsMat.getString("material_name");
                                            double extraPrice = rsMat.getDouble("extra_price");

                                            String safeType = matType == null ? "" : matType.trim().replaceAll("\\s+", "_");

                                            String imgName = rsMat.getString("image_name");
                                            String imgEncoded = java.net.URLEncoder.encode(imgName == null ? "" : imgName, "UTF-8");

                                            boolean isChecked = (matName != null && matName.equals(selectedShirtMat));
                                    %>
                                    <div class="fabric-list col-md-3 col-6" data-type="<%= safeType%>">
                                        <label class="w-100">
                                            <input type="radio" name="shirtPattern" value="<%= matName%>" class="d-none"
                                                   <%= isChecked ? "checked" : ""%> <%= bolehEdit ? "" : "disabled"%> required>
                                            <div class="fabric-item">
                                                <img src="displayImage?type=material&name=<%= imgEncoded%>"
                                                     onerror="this.src='https://via.placeholder.com/150?text=Fabric'">
                                                <div class="small mt-2"><%= matName%> (+RM <%= String.format("%.2f", extraPrice)%>)</div>
                                            </div>
                                        </label>
                                    </div>
                                    <% }%>
                                </div>

                                <hr>

                                <div class="section-title fw-bold mb-3">2. BOTTOM PATTERN (SKIRT/PANTS)</div>

                                <div class="form-check form-switch mb-3 p-3 bg-light border rounded">
                                    <input class="form-check-input ms-0 me-2" type="checkbox" id="syncFabric" name="syncFabric"
                                           onchange="toggleSkirtSelection()" <%= bolehEdit ? "" : "disabled"%>>

                                    <label class="form-check-label fw-bold" for="syncFabric">Sedondon (Ikut Baju)</label>
                                </div>

                                <div id="skirtSelectionArea">
                                    <!-- Type dropdown (view only) -->
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label fw-bold">Jenis Material Fabric (Type)</label>
                                            <select id="skirtFabricType" class="form-select" onchange="filterFabric('skirt')" <%= bolehEdit ? "" : "disabled"%>>
                                                <option value="" data-key="">-- Select Material --</option>
                                                <%
                                                    rsType.beforeFirst();
                                                    while (rsType.next()) {
                                                        String matType = rsType.getString("material_type");
                                                        String safeType = matType == null ? "" : matType.trim().replaceAll("\\s+", "_");
                                                %>
                                                <option value="<%= matType%>" data-key="<%= safeType%>"><%= matType%></option>
                                                <% } %>
                                            </select>
                                        </div>
                                    </div>

                                    <!-- Cards Fabric (VIEW ONLY) -->
                                    <div id="skirtFabricContainer" class="row g-2 mb-4">
                                        <%
                                            rsMat.beforeFirst();
                                            while (rsMat.next()) {
                                                String matType = rsMat.getString("material_type");
                                                String matName = rsMat.getString("material_name");
                                                double extraPrice = rsMat.getDouble("extra_price");

                                                String safeType = matType == null ? "" : matType.trim().replaceAll("\\s+", "_");

                                                String imgName = rsMat.getString("image_name");
                                                String imgEncoded = java.net.URLEncoder.encode(imgName == null ? "" : imgName, "UTF-8");

                                                boolean isChecked = (matName != null && matName.equals(selectedSkirtMat));
                                        %>
                                        <div class="fabric-list col-md-3 col-6" data-type="<%= safeType%>">
                                            <label class="w-100">
                                                <input type="radio" name="skirtPattern" value="<%= matName%>" class="d-none"
                                                       <%= isChecked ? "checked" : ""%> <%= bolehEdit ? "" : "disabled"%> required>
                                                <div class="fabric-item">
                                                    <img src="displayImage?type=material&name=<%= imgEncoded%>"
                                                         onerror="this.src='https://via.placeholder.com/150?text=Fabric'">
                                                    <div class="small mt-2"><%= matName%> (+RM <%= String.format("%.2f", extraPrice)%>)</div>
                                                </div>
                                            </label>
                                        </div>
                                        <% }%>
                                    </div>
                                </div>

                                <h6 class="fw-bold border-bottom pb-2 mb-3 text-uppercase">
                                    <i class="fas fa-ruler-combined me-2"></i>SIZE DETAILS
                                </h6>

                                <div class="row g-3">
                                    <div class="col-md-4">
                                        <label class="form-label small">Top Size</label>
                                        <select name="topSize" class="form-select" <%= bolehEdit ? "" : "disabled"%>>
                                            <option value="XS">XS</option>
                                            <option value="S">S</option>
                                            <option value="M">M</option>
                                            <option value="L">L</option>
                                            <option value="XL">XL</option>
                                            <option value="XXL">XXL</option>
                                        </select>
                                    </div>

                                    <div class="col-md-4">
                                        <label class="form-label small">Bottom Size</label>
                                        <select name="bottomSize" class="form-select" <%= bolehEdit ? "" : "disabled"%>>
                                            <option value="XS">XS</option>
                                            <option value="S">S</option>
                                            <option value="M">M</option>
                                            <option value="L">L</option>
                                            <option value="XL">XL</option>
                                            <option value="XXL">XXL</option>
                                        </select>
                                    </div>

                                    <div class="col-md-4">
                                        <label class="form-label small">Fit Preference</label>
                                        <select name="fitPreference" class="form-select" <%= bolehEdit ? "" : "disabled"%>>
                                            <option value="">-- Select --</option>
                                            <option value="Slim Fit">Slim Fit</option>
                                            <option value="Regular Fit">Regular Fit</option>
                                            <option value="Loose Fit">Loose Fit</option>
                                        </select>
                                    </div>

                                    <div class="col-md-4">
                                        <label class="form-label small">Height (cm)</label>
                                        <input type="text" name="heightCm" class="form-control"
                                               value="<%= rsOrder.getString("height_cm")%>"
                                               <%= bolehEdit ? "" : "readonly"%>>
                                    </div>

                                    <div class="col-md-4">
                                        <label class="form-label small">Weight (kg)</label>
                                        <input type="text" name="weightKg" class="form-control"
                                               value="<%= rsOrder.getString("weight_kg")%>"
                                               <%= bolehEdit ? "" : "readonly"%>>
                                    </div>

                                    <div class="col-md-12">
                                        <label class="form-label small">Special Request</label>
                                        <textarea name="specialRequest" class="form-control"
                                                  <%= bolehEdit ? "" : "readonly"%>><%= rsOrder.getString("special_request")%></textarea>
                                    </div>
                                </div>

                                <% if (bolehEdit) { %>
                                <div class="mt-5 text-center">
                                    <button type="submit" class="btn btn-success btn-lg px-5 shadow-sm w-100">
                                        <i class="fas fa-save me-2"></i>SAVE CHANGES
                                    </button>
                                    <div class="alert alert-warning mt-3 py-2 small">
                                        <i class="fas fa-exclamation-triangle me-1"></i>
                                        You can only update measurements before payment is made.
                                    </div>
                                </div>
                                <% } else { %>
                                <div class="mt-5 text-center">
                                    <button type="button" class="btn btn-secondary btn-lg px-5 w-100" disabled>
                                        <i class="fas fa-lock me-2"></i>VIEW ONLY MODE
                                    </button>
                                    <p class="small text-muted mt-2">This order is already processing or has been paid.</p>
                                </div>
                                <% } %>

                                <div class="text-center mt-3">
                                    <a href="order-history.jsp" class="btn btn-link text-decoration-none text-muted">
                                        <i class="fas fa-arrow-left me-1"></i> Back to My Orders
                                    </a>
                                </div>
                            </form>
                        </div>

                        <script>
                            function filterFabric(type) {
                            const select = document.getElementById(type + 'FabricType');
                            const container = document.getElementById(type + 'FabricContainer');
                            container.querySelectorAll('.fabric-list').forEach(el => el.style.display = 'none');
                            if (select && select.value) {
                            const key = select.selectedOptions[0].dataset.key;
                            container.querySelectorAll('.fabric-list[data-type="' + key + '"]').forEach(el => {
                            el.style.display = 'block';
                            });
                            }
                            }

                            function toggleSkirtSelection() {
                            const sync = document.getElementById('syncFabric');
                            const skirtArea = document.getElementById('skirtSelectionArea');
                            if (!sync || !skirtArea) return;
                            if (sync.checked) {
                            skirtArea.style.opacity = '0.5';
                            skirtArea.style.pointerEvents = 'none';
                            // auto check bottom fabric based on top fabric
                            const shirtRadio = document.querySelector('input[name="shirtPattern"]:checked');
                            if (shirtRadio) {
                            const skirtRadio = document.querySelector('input[name="skirtPattern"][value="' + shirtRadio.value.replace(/"/g, '\\"') + '"]');
                            if (skirtRadio) skirtRadio.checked = true;
                            }
                            } else {
                            skirtArea.style.opacity = '1';
                            skirtArea.style.pointerEvents = 'auto';
                            }
                            }
                            document.addEventListener('change', function(e){
                            if (e.target && e.target.name === 'shirtPattern') {
                            if (document.getElementById('syncFabric')?.checked) toggleSkirtSelection();
                            }
                            });
                            window.onload = function () {
                            // Auto tick matching fabric when same value
                            const shirtVal = document.querySelector('input[name="shirtPattern"]:checked')?.value || "";
                            const skirtVal = document.querySelector('input[name="skirtPattern"]:checked')?.value || "";
                            if (shirtVal === skirtVal && shirtVal !== "") {
                            const sync = document.getElementById('syncFabric');
                            if (sync) sync.checked = true;
                            toggleSkirtSelection();
                            }

                            // Auto set dropdown type based on checked card
                            const shirtChecked = document.querySelector('#shirtFabricContainer input[name="shirtPattern"]:checked');
                            if (shirtChecked) {
                            const card = shirtChecked.closest('.fabric-list');
                            if (card) {
                            const typeKey = card.dataset.type;
                            const ddl = document.getElementById('shirtFabricType');
                            const opt = ddl?.querySelector('option[data-key="' + typeKey + '"]');
                            if (ddl && opt) ddl.value = opt.value;
                            filterFabric('shirt');
                            }
                            }

                            // Auto set dropdown TYPE ikut card yang checked (kain)
                            const skirtChecked = document.querySelector('#skirtFabricContainer input[name="skirtPattern"]:checked');
                            if (skirtChecked) {
                            const card = skirtChecked.closest('.fabric-list');
                            if (card) {
                            const typeKey = card.dataset.type;
                            const ddl = document.getElementById('skirtFabricType');
                            const opt = ddl?.querySelector('option[data-key="' + typeKey + '"]');
                            if (ddl && opt) ddl.value = opt.value;
                            filterFabric('skirt');
                            }
                            }
                            };
                        </script>

                        <%
                            } // end if order found
                        } catch (Exception e) {
                        %>
                        <div class="alert alert-danger m-4">Error: <%= e.getMessage()%></div>
                        <%
                            } finally {
                                try {
                                    if (rsType != null) {
                                        rsType.close();
                                    }
                                } catch (Exception ignore) {
                                }
                                try {
                                    if (rsMat != null) {
                                        rsMat.close();
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
                                    if (stmtMat != null) {
                                        stmtMat.close();
                                    }
                                } catch (Exception ignore) {
                                }
                                try {
                                    if (rsOrder != null) {
                                        rsOrder.close();
                                    }
                                } catch (Exception ignore) {
                                }
                                try {
                                    if (psOrder != null) {
                                        psOrder.close();
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

                    </div>
                </div>
            </div>
        </div>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
