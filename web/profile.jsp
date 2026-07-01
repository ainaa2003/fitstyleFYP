<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="fitstyle.dao.UserDAO"%>
<%@page import="fitstyle.model.User"%>

<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    private String regionFromState(String state) {
        if (state == null) return "WEST";
        String st = state.trim();
        if ("Sabah".equalsIgnoreCase(st) || "Sarawak".equalsIgnoreCase(st)) return "EAST";
        return "WEST";
    }

    private String regionDisplay(String region) {
        return "EAST".equalsIgnoreCase(region) ? "Sabah/Sarawak" : "Semenanjung Malaysia";
    }

    private String selected(String value, String current) {
        return value != null && current != null && value.equalsIgnoreCase(current) ? "selected" : "";
    }
%>

<%
    Object uid = session.getAttribute("userId");
    if (uid == null) {
        response.sendRedirect("login.jsp?msg=Please login first");
        return;
    }

    int customerId = Integer.parseInt(uid.toString());
    UserDAO userDAO = new UserDAO();
    User profile = userDAO.getUserById(customerId);
    if (profile == null) {
        response.sendRedirect("index.jsp?msg=Profile not found");
        return;
    }

    String role = profile.getRole() == null ? "" : profile.getRole();
    String phone = profile.getPhone() == null ? "" : profile.getPhone();
    String address = profile.getAddress() == null ? "" : profile.getAddress();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String addressMsg = request.getParameter("addressMsg");
    String editAddressIdParam = request.getParameter("editAddressId");

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();

        String addressAction = request.getParameter("addressAction");

        if ("customer".equals(role) && "addAddress".equals(addressAction) && "POST".equalsIgnoreCase(request.getMethod())) {
            String label = request.getParameter("label");
            String recipient = request.getParameter("recipientName");
            String addrPhone = request.getParameter("addressPhone");
            String line1 = request.getParameter("addressLine1");
            String line2 = request.getParameter("addressLine2");
            String city = request.getParameter("city");
            String postcode = request.getParameter("postcode");
            String state = request.getParameter("state");
            String region = regionFromState(state);
            boolean makeDefault = request.getParameter("isDefault") != null;

            ps = conn.prepareStatement("SELECT COUNT(*) FROM customer_addresses WHERE customer_id=?");
            ps.setInt(1, customerId);
            rs = ps.executeQuery();
            int count = 0;
            if (rs.next()) count = rs.getInt(1);
            rs.close(); ps.close();

            if (makeDefault || count == 0) {
                ps = conn.prepareStatement("UPDATE customer_addresses SET is_default=0 WHERE customer_id=?");
                ps.setInt(1, customerId);
                ps.executeUpdate();
                ps.close();
            }

            ps = conn.prepareStatement("INSERT INTO customer_addresses (customer_id, label, recipient_name, phone, address_line1, address_line2, city, postcode, state, region, is_default) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
            ps.setInt(1, customerId);
            ps.setString(2, label == null || label.trim().isEmpty() ? "Home" : label.trim());
            ps.setString(3, recipient);
            ps.setString(4, addrPhone);
            ps.setString(5, line1);
            ps.setString(6, line2);
            ps.setString(7, city);
            ps.setString(8, postcode);
            ps.setString(9, state);
            ps.setString(10, region);
            ps.setBoolean(11, makeDefault || count == 0);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("profile.jsp?addressMsg=added#addresses");
            return;
        }

        if ("customer".equals(role) && "updateAddress".equals(addressAction) && "POST".equalsIgnoreCase(request.getMethod())) {
            int addressId = Integer.parseInt(request.getParameter("addressId"));
            String label = request.getParameter("label");
            String recipient = request.getParameter("recipientName");
            String addrPhone = request.getParameter("addressPhone");
            String line1 = request.getParameter("addressLine1");
            String line2 = request.getParameter("addressLine2");
            String city = request.getParameter("city");
            String postcode = request.getParameter("postcode");
            String state = request.getParameter("state");
            String region = regionFromState(state);
            boolean makeDefault = request.getParameter("isDefault") != null;

            if (makeDefault) {
                ps = conn.prepareStatement("UPDATE customer_addresses SET is_default=0 WHERE customer_id=?");
                ps.setInt(1, customerId);
                ps.executeUpdate();
                ps.close();
            }

            ps = conn.prepareStatement("UPDATE customer_addresses SET label=?, recipient_name=?, phone=?, address_line1=?, address_line2=?, city=?, postcode=?, state=?, region=?, is_default=IF(?,1,is_default) WHERE customer_id=? AND address_id=?");
            ps.setString(1, label == null || label.trim().isEmpty() ? "Home" : label.trim());
            ps.setString(2, recipient);
            ps.setString(3, addrPhone);
            ps.setString(4, line1);
            ps.setString(5, line2);
            ps.setString(6, city);
            ps.setString(7, postcode);
            ps.setString(8, state);
            ps.setString(9, region);
            ps.setBoolean(10, makeDefault);
            ps.setInt(11, customerId);
            ps.setInt(12, addressId);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("profile.jsp?addressMsg=updated#addresses");
            return;
        }

        if ("customer".equals(role) && "setDefaultAddress".equals(addressAction)) {
            int addressId = Integer.parseInt(request.getParameter("addressId"));
            ps = conn.prepareStatement("UPDATE customer_addresses SET is_default=0 WHERE customer_id=?");
            ps.setInt(1, customerId);
            ps.executeUpdate();
            ps.close();

            ps = conn.prepareStatement("UPDATE customer_addresses SET is_default=1 WHERE customer_id=? AND address_id=?");
            ps.setInt(1, customerId);
            ps.setInt(2, addressId);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("profile.jsp?addressMsg=default_updated#addresses");
            return;
        }

        if ("customer".equals(role) && "deleteAddress".equals(addressAction)) {
            int addressId = Integer.parseInt(request.getParameter("addressId"));
            ps = conn.prepareStatement("DELETE FROM customer_addresses WHERE customer_id=? AND address_id=?");
            ps.setInt(1, customerId);
            ps.setInt(2, addressId);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("profile.jsp?addressMsg=deleted#addresses");
            return;
        }
    } catch (Exception ex) {
        request.setAttribute("addressError", ex.getMessage());
    } finally {
        try { if (rs != null) rs.close(); } catch(Exception ignore) {}
        try { if (ps != null) ps.close(); } catch(Exception ignore) {}
        try { if (conn != null) conn.close(); } catch(Exception ignore) {}
    }
%>
<!DOCTYPE html>
<html>
<head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>My Profile | FitStyle</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background:#f4f7f6; font-family:'Poppins', sans-serif; }
        .profile-card { max-width: 950px; margin: 45px auto; border: none; border-radius: 18px; box-shadow: 0 8px 25px rgba(0,0,0,.08); overflow: hidden; }
        .profile-header { background: var(--primary); color: white; padding: 28px; }
        .profile-header h3 { color: var(--gold); margin: 0; font-weight: 700; }
        .avatar { width: 80px; height: 80px; border-radius: 50%; background: var(--gold); color: var(--primary); display:flex; align-items:center; justify-content:center; font-size:32px; font-weight:700; }
        .btn-save { background: var(--primary); color: var(--gold); font-weight: 600; border: none; }
        .btn-save:hover { background: var(--gold); color: var(--primary); }
        .sidebar { background-color: var(--primary); min-height: 100vh; color: white; padding-top: 20px; }
        .sidebar .nav-link { color: rgba(255,255,255,0.8); margin-bottom: 10px; transition: 0.3s; border-radius: 8px; padding: 10px 12px; }
        .sidebar .nav-link:hover, .sidebar .nav-link.active { color: var(--gold); background: rgba(212, 175, 55, 0.1); }
        .address-card { border:1px solid #e9ecef; border-radius:14px; padding:16px; background:#fff; height:100%; }
        .address-form-box { background:#f8faf9; border:1px solid #e4e8e6; border-radius:14px; padding:18px; }
    </style>
</head>
<body>
    <jsp:include page="includes/navbar.jsp" />

    <% if ("customer".equals(role)) { %>
    <div class="container-fluid">
        <div class="row">
            <nav class="col-md-2 d-none d-md-block sidebar text-center px-3">
                <div class="position-sticky">
                    <i class="fas fa-user-circle fa-4x mb-3" style="color: var(--gold)"></i>
                    <h6 class="mb-4 text-white text-uppercase"><%= profile.getFullName() %></h6>
                    <ul class="nav flex-column text-start">
                        <li class="nav-item"><a class="nav-link" href="customer-dashboard.jsp"><i class="fas fa-home me-2"></i> Dashboard</a></li>
                        <li class="nav-item"><a class="nav-link" href="order-history.jsp"><i class="fas fa-shopping-bag me-2"></i> My Orders</a></li>
                        <li class="nav-item"><a class="nav-link" href="measurement-record.jsp"><i class="fas fa-ruler-combined me-2"></i> Measurement Records</a></li>
                        <li class="nav-item"><a class="nav-link active" href="profile.jsp"><i class="fas fa-id-card me-2"></i> My Profile</a></li>
                        <li class="nav-item"><a class="nav-link" href="auth-controller?action=logout"><i class="fas fa-sign-out-alt me-2"></i> Logout</a></li>
                    </ul>
                </div>
            </nav>
            <main class="col-md-10 p-4">
    <% } else { %>
    <div class="container">
    <% } %>

        <div class="card profile-card">
            <div class="profile-header d-flex align-items-center gap-3">
                <div class="avatar"><%= profile.getFullName().substring(0,1).toUpperCase() %></div>
                <div>
                    <h3>Manage User Profile</h3>
                    <div><%= profile.getDisplayId() %> • <%= role.toUpperCase() %></div>
                </div>
            </div>

            <div class="card-body p-4">
                <% if (request.getParameter("msg") != null) { %>
                    <div class="alert alert-success"><i class="fas fa-check-circle me-2"></i><%= request.getParameter("msg") %></div>
                <% } %>
                <% if (request.getParameter("error") != null) { %>
                    <div class="alert alert-danger"><i class="fas fa-triangle-exclamation me-2"></i><%= request.getParameter("error") %></div>
                <% } %>

                <form action="auth-controller" method="POST">
                    <input type="hidden" name="action" value="updateProfile">
                    <input type="hidden" name="address" value="<%= esc(address) %>">

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label fw-bold">Full Name</label>
                            <input type="text" name="name" class="form-control" value="<%= esc(profile.getFullName()) %>" required>
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label fw-bold">Email</label>
                            <input type="email" name="email" class="form-control" value="<%= esc(profile.getEmail()) %>" required>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label fw-bold">Phone Number</label>
                            <input type="text" name="phone" class="form-control" value="<%= esc(phone) %>">
                        </div>
                        <div class="col-md-6 mb-3">
                            <label class="form-label fw-bold">New Password <span class="text-muted fw-normal">(leave blank if not changing)</span></label>
                            <input type="password" name="newPassword" class="form-control" placeholder="Enter new password">
                        </div>
                    </div>

                    <button type="submit" class="btn btn-save px-4"><i class="fas fa-save me-2"></i>Save Profile</button>
                    <% if ("customer".equals(role)) { %>
                        <a href="customer-dashboard.jsp" class="btn btn-outline-secondary ms-2">Cancel</a>
                    <% } else { %>
                        <a href="index.jsp" class="btn btn-outline-secondary ms-2">Cancel</a>
                    <% } %>
                </form>

                <% if ("customer".equals(role)) { %>
                <hr class="my-4" id="addresses">
                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2 mb-3">
                    <div>
                        <h4 class="fw-bold mb-1" style="color:var(--primary);">
                            <i class="fas fa-map-marker-alt me-2"></i>My Addresses
                        </h4>
                        <div class="text-muted small">Save multiple delivery addresses and choose one during checkout.</div>
                    </div>
                </div>

                <% if ("added".equals(addressMsg)) { %><div class="alert alert-success">Address added successfully.</div><% } %>
                <% if ("updated".equals(addressMsg)) { %><div class="alert alert-success">Address updated successfully.</div><% } %>
                <% if ("deleted".equals(addressMsg)) { %><div class="alert alert-success">Address deleted successfully.</div><% } %>
                <% if ("default_updated".equals(addressMsg)) { %><div class="alert alert-success">Default address updated.</div><% } %>
                <% if (request.getAttribute("addressError") != null) { %>
                    <div class="alert alert-danger">Address error: <%= esc(request.getAttribute("addressError").toString()) %></div>
                <% } %>

                <div class="row g-3 mb-4">
                    <%
                        String editLabel = "";
                        String editRecipient = "";
                        String editPhone = "";
                        String editLine1 = "";
                        String editLine2 = "";
                        String editCity = "";
                        String editPostcode = "";
                        String editState = "";
                        boolean editDefault = false;
                        boolean isEditingAddress = false;

                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            conn = fitstyle.util.DBConnection.getConnection();

                            if (editAddressIdParam != null && !editAddressIdParam.trim().isEmpty()) {
                                ps = conn.prepareStatement("SELECT * FROM customer_addresses WHERE customer_id=? AND address_id=?");
                                ps.setInt(1, customerId);
                                ps.setInt(2, Integer.parseInt(editAddressIdParam));
                                rs = ps.executeQuery();
                                if (rs.next()) {
                                    isEditingAddress = true;
                                    editLabel = rs.getString("label");
                                    editRecipient = rs.getString("recipient_name");
                                    editPhone = rs.getString("phone");
                                    editLine1 = rs.getString("address_line1");
                                    editLine2 = rs.getString("address_line2");
                                    editCity = rs.getString("city");
                                    editPostcode = rs.getString("postcode");
                                    editState = rs.getString("state");
                                    editDefault = rs.getBoolean("is_default");
                                }
                                rs.close(); ps.close();
                            }

                            ps = conn.prepareStatement("SELECT * FROM customer_addresses WHERE customer_id=? ORDER BY is_default DESC, address_id DESC");
                            ps.setInt(1, customerId);
                            rs = ps.executeQuery();
                            boolean hasAddress = false;
                            while (rs.next()) {
                                hasAddress = true;
                    %>
                    <div class="col-md-6">
                        <div class="address-card">
                            <div class="d-flex justify-content-between align-items-start gap-2">
                                <div>
                                    <strong><%= esc(rs.getString("label")) %></strong>
                                    <% if (rs.getBoolean("is_default")) { %><span class="badge bg-success ms-1">Default</span><% } %>
                                </div>
                                <span class="badge" style="background:var(--primary); color:var(--gold);"><%= regionDisplay(rs.getString("region")) %></span>
                            </div>
                            <div class="small mt-2">
                                <strong><%= esc(rs.getString("recipient_name")) %></strong><br>
                                <%= esc(rs.getString("phone")) %><br>
                                <%= esc(rs.getString("address_line1")) %><br>
                                <% if (rs.getString("address_line2") != null && !rs.getString("address_line2").trim().isEmpty()) { %><%= esc(rs.getString("address_line2")) %><br><% } %>
                                <%= esc(rs.getString("postcode")) %> <%= esc(rs.getString("city")) %>, <%= esc(rs.getString("state")) %>
                            </div>
                            <div class="mt-3 d-flex gap-2 flex-wrap">
                                <a class="btn btn-sm btn-outline-primary" href="profile.jsp?editAddressId=<%= rs.getInt("address_id") %>#addressForm">Edit</a>
                                <% if (!rs.getBoolean("is_default")) { %>
                                <a class="btn btn-sm btn-outline-success" href="profile.jsp?addressAction=setDefaultAddress&addressId=<%= rs.getInt("address_id") %>#addresses">Set Default</a>
                                <% } %>
                                <a class="btn btn-sm btn-outline-danger" href="profile.jsp?addressAction=deleteAddress&addressId=<%= rs.getInt("address_id") %>" onclick="return confirm('Delete this address?');">Delete</a>
                            </div>
                        </div>
                    </div>
                    <%
                            }
                            if (!hasAddress) {
                    %>
                    <div class="col-12"><div class="alert alert-warning mb-0">No address saved yet. Please add one below.</div></div>
                    <%
                            }
                        } catch (Exception ex) {
                    %>
                    <div class="col-12"><div class="alert alert-danger">Address list error: <%= esc(ex.getMessage()) %></div></div>
                    <%
                        } finally {
                            try { if (rs != null) rs.close(); } catch(Exception ignore) {}
                            try { if (ps != null) ps.close(); } catch(Exception ignore) {}
                            try { if (conn != null) conn.close(); } catch(Exception ignore) {}
                        }
                    %>
                </div>

                <div class="address-form-box" id="addressForm">
                    <h5 class="fw-bold mb-3" style="color:var(--primary);"><%= isEditingAddress ? "Edit Address" : "Add New Address" %></h5>
                    <form method="POST" action="profile.jsp#addresses">
                        <input type="hidden" name="addressAction" value="<%= isEditingAddress ? "updateAddress" : "addAddress" %>">
                        <% if (isEditingAddress) { %>
                            <input type="hidden" name="addressId" value="<%= editAddressIdParam %>">
                        <% } %>
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-bold">Address Label</label>
                                <input type="text" name="label" class="form-control" placeholder="Home / Hostel / Office" value="<%= esc(editLabel) %>" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">Recipient Name</label>
                                <input type="text" name="recipientName" class="form-control" value="<%= esc(editRecipient) %>" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">Phone Number</label>
                                <input type="text" name="addressPhone" class="form-control" value="<%= esc(editPhone) %>" required>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label fw-bold">Address Line 1</label>
                                <input type="text" name="addressLine1" class="form-control" placeholder="House no, street, building" value="<%= esc(editLine1) %>" required>
                            </div>
                            <div class="col-md-12">
                                <label class="form-label fw-bold">Address Line 2 <span class="text-muted small">(Optional)</span></label>
                                <input type="text" name="addressLine2" class="form-control" placeholder="Apartment, unit, landmark" value="<%= esc(editLine2) %>">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">City</label>
                                <input type="text" name="city" class="form-control" value="<%= esc(editCity) %>" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">Postcode</label>
                                <input type="text" name="postcode" class="form-control" value="<%= esc(editPostcode) %>" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">State</label>
                                <select name="state" class="form-select" required>
                                    <option value="">-- Choose State --</option>
                                    <option <%= selected("Johor", editState) %>>Johor</option>
                                    <option <%= selected("Kedah", editState) %>>Kedah</option>
                                    <option <%= selected("Kelantan", editState) %>>Kelantan</option>
                                    <option <%= selected("Melaka", editState) %>>Melaka</option>
                                    <option <%= selected("Negeri Sembilan", editState) %>>Negeri Sembilan</option>
                                    <option <%= selected("Pahang", editState) %>>Pahang</option>
                                    <option <%= selected("Perak", editState) %>>Perak</option>
                                    <option <%= selected("Perlis", editState) %>>Perlis</option>
                                    <option <%= selected("Pulau Pinang", editState) %>>Pulau Pinang</option>
                                    <option <%= selected("Selangor", editState) %>>Selangor</option>
                                    <option <%= selected("Terengganu", editState) %>>Terengganu</option>
                                    <option <%= selected("W.P. Kuala Lumpur", editState) %>>W.P. Kuala Lumpur</option>
                                    <option <%= selected("W.P. Putrajaya", editState) %>>W.P. Putrajaya</option>
                                    <option <%= selected("W.P. Labuan", editState) %>>W.P. Labuan</option>
                                    <option <%= selected("Sabah", editState) %>>Sabah</option>
                                    <option <%= selected("Sarawak", editState) %>>Sarawak</option>
                                </select>
                                <div class="small text-muted mt-1">Sabah/Sarawak will use East Malaysia shipping rate.</div>
                            </div>
                            <div class="col-12">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="isDefault" id="isDefault" <%= editDefault ? "checked" : "" %>>
                                    <label class="form-check-label" for="isDefault">Set as default address</label>
                                </div>
                            </div>
                            <div class="col-12">
                                <button type="submit" class="btn btn-save px-4"><i class="fas fa-save me-1"></i> <%= isEditingAddress ? "Update Address" : "Save Address" %></button>
                                <% if (isEditingAddress) { %><a href="profile.jsp#addresses" class="btn btn-outline-secondary ms-2">Cancel Edit</a><% } %>
                            </div>
                        </div>
                    </form>
                </div>
                <% } %>
            </div>
        </div>

    <% if ("customer".equals(role)) { %>
            </main>
        </div>
    </div>
    <% } else { %>
    </div>
    <% } %>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
