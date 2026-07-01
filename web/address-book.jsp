<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>

<%!
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }

    private String regionFromState(String state) {
        if (state == null) return "WEST";
        if ("Sabah".equalsIgnoreCase(state.trim()) || "Sarawak".equalsIgnoreCase(state.trim())) return "EAST";
        return "WEST";
    }

    private String regionDisplay(String region) {
        return "EAST".equalsIgnoreCase(region) ? "Sabah/Sarawak" : "Semenanjung Malaysia";
    }
%>

<%
    if (session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp?msg=Please login first");
        return;
    }
    if ("tailor".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("tailor-dashboard.jsp");
        return;
    }

    int customerId = Integer.parseInt(session.getAttribute("userId").toString());
    String returnTo = request.getParameter("returnTo") == null ? "" : request.getParameter("returnTo");
    String ids = request.getParameter("ids") == null ? "" : request.getParameter("ids");
    String backUrl = "payment".equals(returnTo) && !ids.trim().isEmpty() ? "payment.jsp?ids=" + ids : "profile.jsp";

    String msg = request.getParameter("msg");
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = fitstyle.util.DBConnection.getConnection();

        String action = request.getParameter("action");

        if ("add".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String label = request.getParameter("label");
            String recipient = request.getParameter("recipientName");
            String phone = request.getParameter("phone");
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

            ps = conn.prepareStatement("SELECT COUNT(*) FROM customer_addresses WHERE customer_id=?");
            ps.setInt(1, customerId);
            rs = ps.executeQuery();
            int count = 0;
            if (rs.next()) count = rs.getInt(1);
            rs.close(); ps.close();

            ps = conn.prepareStatement("INSERT INTO customer_addresses (customer_id, label, recipient_name, phone, address_line1, address_line2, city, postcode, state, region, is_default) VALUES (?,?,?,?,?,?,?,?,?,?,?)");
            ps.setInt(1, customerId);
            ps.setString(2, label == null || label.trim().isEmpty() ? "Home" : label.trim());
            ps.setString(3, recipient);
            ps.setString(4, phone);
            ps.setString(5, line1);
            ps.setString(6, line2);
            ps.setString(7, city);
            ps.setString(8, postcode);
            ps.setString(9, state);
            ps.setString(10, region);
            ps.setBoolean(11, makeDefault || count == 0);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("address-book.jsp?returnTo=" + returnTo + "&ids=" + ids + "&msg=added");
            return;
        }

        if ("update".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            int addressId = Integer.parseInt(request.getParameter("addressId"));
            String label = request.getParameter("label");
            String recipient = request.getParameter("recipientName");
            String phone = request.getParameter("phone");
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

            ps = conn.prepareStatement("UPDATE customer_addresses SET label=?, recipient_name=?, phone=?, address_line1=?, address_line2=?, city=?, postcode=?, state=?, region=?, is_default=? WHERE customer_id=? AND address_id=?");
            ps.setString(1, label == null || label.trim().isEmpty() ? "Home" : label.trim());
            ps.setString(2, recipient);
            ps.setString(3, phone);
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

            response.sendRedirect("address-book.jsp?returnTo=" + returnTo + "&ids=" + ids + "&msg=updated");
            return;
        }

        String editLabel = "";
        String editRecipient = "";
        String editPhone = "";
        String editLine1 = "";
        String editLine2 = "";
        String editCity = "";
        String editPostcode = "";
        String editState = "";
        boolean editDefault = false;
        int editAddressId = 0;
        boolean isEditAddress = "edit".equals(action) && request.getParameter("addressId") != null;

        if (isEditAddress) {
            editAddressId = Integer.parseInt(request.getParameter("addressId"));
            ps = conn.prepareStatement("SELECT * FROM customer_addresses WHERE customer_id=? AND address_id=?");
            ps.setInt(1, customerId);
            ps.setInt(2, editAddressId);
            rs = ps.executeQuery();
            if (rs.next()) {
                editLabel = rs.getString("label");
                editRecipient = rs.getString("recipient_name");
                editPhone = rs.getString("phone");
                editLine1 = rs.getString("address_line1");
                editLine2 = rs.getString("address_line2");
                editCity = rs.getString("city");
                editPostcode = rs.getString("postcode");
                editState = rs.getString("state");
                editDefault = rs.getBoolean("is_default");
            } else {
                isEditAddress = false;
            }
            rs.close();
            ps.close();
        }

        if ("setDefault".equals(action)) {
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

            response.sendRedirect("address-book.jsp?returnTo=" + returnTo + "&ids=" + ids + "&msg=default_updated");
            return;
        }

        if ("delete".equals(action)) {
            int addressId = Integer.parseInt(request.getParameter("addressId"));
            ps = conn.prepareStatement("DELETE FROM customer_addresses WHERE customer_id=? AND address_id=?");
            ps.setInt(1, customerId);
            ps.setInt(2, addressId);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("address-book.jsp?returnTo=" + returnTo + "&ids=" + ids + "&msg=deleted");
            return;
        }
%>

<!DOCTYPE html>
<html>
<head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta charset="UTF-8">
    <title>Address Book | FitStyle</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body { background:#f4f7f6; font-family:'Poppins', sans-serif; }
        .page-card { max-width:1000px; margin:35px auto; border:none; border-radius:18px; box-shadow:0 8px 25px rgba(0,0,0,.08); overflow:hidden; }
        .page-header { background:#043927; color:#fff; padding:25px; }
        .page-header h3 { color:#D4AF37; margin:0; font-weight:700; }
        .address-card { border:1px solid #e9ecef; border-radius:14px; padding:16px; background:#fff; height:100%; }
        .btn-main { background:#043927; color:#D4AF37; border:none; font-weight:600; }
        .btn-main:hover { background:#D4AF37; color:#043927; }
    </style>
</head>
<body>
<%@include file="includes/navbar.jsp" %>

<div class="container">
    <div class="card page-card">
        <div class="page-header d-flex justify-content-between align-items-center flex-wrap gap-2">
            <div>
                <h3><i class="fas fa-map-marker-alt me-2"></i>My Address Book</h3>
                <div class="small text-white-50">Save multiple delivery addresses and choose one during checkout.</div>
            </div>
            <a href="<%= backUrl %>" class="btn btn-outline-light btn-sm fw-bold">Back</a>
        </div>

        <div class="card-body p-4">
            <% if ("added".equals(msg)) { %><div class="alert alert-success">Address added successfully.</div><% } %>
            <% if ("deleted".equals(msg)) { %><div class="alert alert-success">Address deleted successfully.</div><% } %>
            <% if ("default_updated".equals(msg)) { %><div class="alert alert-success">Default address updated.</div><% } %>
            <% if ("updated".equals(msg)) { %><div class="alert alert-success">Address updated successfully.</div><% } %>

            <h5 class="fw-bold mb-3" style="color:#043927;">Saved Addresses</h5>
            <div class="row g-3 mb-4">
                <%
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
                            <span class="badge" style="background:#043927; color:#D4AF37;"><%= regionDisplay(rs.getString("region")) %></span>
                        </div>
                        <div class="small mt-2">
                            <strong><%= esc(rs.getString("recipient_name")) %></strong><br>
                            <%= esc(rs.getString("phone")) %><br>
                            <%= esc(rs.getString("address_line1")) %><br>
                            <% if (rs.getString("address_line2") != null && !rs.getString("address_line2").trim().isEmpty()) { %><%= esc(rs.getString("address_line2")) %><br><% } %>
                            <%= esc(rs.getString("postcode")) %> <%= esc(rs.getString("city")) %>, <%= esc(rs.getString("state")) %>
                        </div>
                        <div class="mt-3 d-flex gap-2 flex-wrap">
                            <a class="btn btn-sm btn-outline-primary" href="address-book.jsp?action=edit&addressId=<%= rs.getInt("address_id") %>&returnTo=<%= returnTo %>&ids=<%= ids %>#addressForm">Edit</a>
                            <% if (!rs.getBoolean("is_default")) { %>
                            <a class="btn btn-sm btn-outline-success" href="address-book.jsp?action=setDefault&addressId=<%= rs.getInt("address_id") %>&returnTo=<%= returnTo %>&ids=<%= ids %>">Set Default</a>
                            <% } %>
                            <a class="btn btn-sm btn-outline-danger" href="address-book.jsp?action=delete&addressId=<%= rs.getInt("address_id") %>&returnTo=<%= returnTo %>&ids=<%= ids %>" onclick="return confirm('Delete this address?');">Delete</a>
                        </div>
                    </div>
                </div>
                <% } if (!hasAddress) { %>
                <div class="col-12"><div class="alert alert-warning">No address saved yet. Please add one below.</div></div>
                <% } try { if (rs != null) rs.close(); } catch(Exception ignore) {} try { if (ps != null) ps.close(); } catch(Exception ignore) {} %>
            </div>

            <hr id="addressForm">
            <h5 class="fw-bold mb-3" style="color:#043927;"><%= isEditAddress ? "Edit Address" : "Add New Address" %></h5>
            <form method="POST" action="address-book.jsp?returnTo=<%= returnTo %>&ids=<%= ids %>">
                <input type="hidden" name="action" value="<%= isEditAddress ? "update" : "add" %>">
                <% if (isEditAddress) { %>
                <input type="hidden" name="addressId" value="<%= editAddressId %>">
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
                        <input type="text" name="phone" class="form-control" value="<%= esc(editPhone) %>" required>
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
                            <option value="Johor" <%= "Johor".equals(editState) ? "selected" : "" %>>Johor</option>
                            <option value="Kedah" <%= "Kedah".equals(editState) ? "selected" : "" %>>Kedah</option>
                            <option value="Kelantan" <%= "Kelantan".equals(editState) ? "selected" : "" %>>Kelantan</option>
                            <option value="Melaka" <%= "Melaka".equals(editState) ? "selected" : "" %>>Melaka</option>
                            <option value="Negeri Sembilan" <%= "Negeri Sembilan".equals(editState) ? "selected" : "" %>>Negeri Sembilan</option>
                            <option value="Pahang" <%= "Pahang".equals(editState) ? "selected" : "" %>>Pahang</option>
                            <option value="Perak" <%= "Perak".equals(editState) ? "selected" : "" %>>Perak</option>
                            <option value="Perlis" <%= "Perlis".equals(editState) ? "selected" : "" %>>Perlis</option>
                            <option value="Pulau Pinang" <%= "Pulau Pinang".equals(editState) ? "selected" : "" %>>Pulau Pinang</option>
                            <option value="Selangor" <%= "Selangor".equals(editState) ? "selected" : "" %>>Selangor</option>
                            <option value="Terengganu" <%= "Terengganu".equals(editState) ? "selected" : "" %>>Terengganu</option>
                            <option value="W.P. Kuala Lumpur" <%= "W.P. Kuala Lumpur".equals(editState) ? "selected" : "" %>>W.P. Kuala Lumpur</option>
                            <option value="W.P. Putrajaya" <%= "W.P. Putrajaya".equals(editState) ? "selected" : "" %>>W.P. Putrajaya</option>
                            <option value="W.P. Labuan" <%= "W.P. Labuan".equals(editState) ? "selected" : "" %>>W.P. Labuan</option>
                            <option value="Sabah" <%= "Sabah".equals(editState) ? "selected" : "" %>>Sabah</option>
                            <option value="Sarawak" <%= "Sarawak".equals(editState) ? "selected" : "" %>>Sarawak</option>
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
                        <button type="submit" class="btn btn-main px-4"><i class="fas fa-save me-1"></i> <%= isEditAddress ? "Update Address" : "Save Address" %></button>
                        <a href="<%= backUrl %>" class="btn btn-outline-secondary ms-2">Cancel</a>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

<%
    } catch (Exception e) {
%>
<div class="container my-4">
    <div class="alert alert-danger">Error: <%= e.getMessage() %><br><small>Please import the updated SQL file if this mentions <b>customer_addresses</b>.</small></div>
    <a href="profile.jsp" class="btn btn-secondary">Back</a>
</div>
<%
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (conn != null) conn.close(); } catch (Exception ignore) {}
    }
%>
