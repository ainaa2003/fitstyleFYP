<%-- 
    Document   : navbar
    Created on : Jan 18, 2026, 3:24:18 AM
    Author     : Acer
--%>

<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
<link rel="stylesheet" href="<%= request.getContextPath()%>/css/responsive.css">

<%
    String userEmail = (String) session.getAttribute("userEmail");
    String userRole = (String) session.getAttribute("userRole");
    String displayName = "";

    String primaryColor = "#043927";   // default emerald
    String hoverColor = "#0a5a3e";     // emerald hover / gradient
    String goldColor = "#D4AF37";

    if ("tailor".equals(userRole)) {
        primaryColor = "#0A1F44";      // navy blue
        hoverColor = "#16356b";        // navy hover / gradient
    }

    if (userEmail != null) {
        displayName = userEmail.split("@")[0];
        displayName = displayName.substring(0, 1).toUpperCase() + displayName.substring(1);
    }
%>

<style>
    :root {
        --primary: <%= primaryColor%>;
        --primary-hover: <%= hoverColor%>;
        --gold: <%= goldColor%>;
        --white: #ffffff;
    }

    .navbar {
        background-color: var(--primary) !important;
        border-bottom: 3px solid var(--gold);
        padding: 10px 0;
        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    }

    .navbar-brand {
        font-family: 'Playfair Display', serif;
        font-size: 26px;
        color: var(--gold) !important;
        font-weight: bold;
        letter-spacing: 2px;
        text-transform: uppercase;
    }

    .navbar-brand span.style-text {
        color: var(--white);
    }

    .user-tag {
        font-family: 'Poppins', sans-serif;
        font-size: 14px;
        color: var(--gold);
        text-transform: none;
        margin-left: 15px;
        padding-left: 15px;
        border-left: 1px solid rgba(212, 175, 55, 0.3);
        font-weight: 400;
    }

    /* Badge Manager & Tailor */
    .role-badge {
        background-color: var(--gold);
        color: var(--primary);
        font-size: 10px;
        padding: 2px 8px;
        border-radius: 4px;
        font-weight: bold;
        margin-left: 8px;
        vertical-align: middle;
        text-transform: uppercase;
    }

    .nav-link {
        font-family: 'Poppins', sans-serif;
        color: var(--white) !important;
        font-weight: 500;
        margin-left: 20px;
        transition: 0.3s;
        text-transform: uppercase;
        font-size: 13px;
    }

    .btn-login-nav, .btn-logout-nav {
        border: 2px solid var(--gold) !important;
        color: var(--gold) !important;
        padding: 6px 20px !important;
        font-weight: 600 !important;
        margin-left: 20px;
        text-decoration: none;
        font-size: 13px;
    }

    .btn-logout-nav {
        border-color: #ff4d4d !important;
        color: #ff4d4d !important;
    }

    .btn-logout-nav:hover {
        background-color: #ff4d4d !important;
        color: white !important;
    }
</style>

<nav class="navbar navbar-expand-lg sticky-top">
    <div class="container">
        <a class="navbar-brand d-flex align-items-center" href="<%= request.getContextPath()%>/index.jsp">
            <img src="<%= request.getContextPath()%>/image/logo.png" alt="FitStyle Logo" style="height:60px; margin-right:12px;">
            FIT<span class="style-text">STYLE</span>
        </a>

        <% if (userEmail != null) { %>
        <span class="user-tag">
            Hi, <%= displayName %>
            <% if ("tailor".equals(userRole)) { %>
                <span class="role-badge">Tailor</span>
            <% } else if ("manager".equals(userRole)) { %>
                <span class="role-badge">Manager</span>
            <% } %>
        </span>
        <% } %>

        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto align-items-center">

                <% if (userEmail != null) { 
                    String dashboardLink = request.getContextPath() + "/customer-dashboard.jsp";
                    String dashboardText = "MY DASHBOARD";
                    String dashboardIcon = "fas fa-user-circle";

                    if ("tailor".equals(userRole)) {
                        dashboardLink = request.getContextPath() + "/tailor-dashboard.jsp";
                        dashboardText = "DASHBOARD";
                        dashboardIcon = "fas fa-scissors";
                    } else if ("manager".equals(userRole)) {
                        dashboardLink = request.getContextPath() + "/manager-dashboard.jsp";
                        dashboardText = "DASHBOARD";
                        dashboardIcon = "fas fa-user-tie";
                    }
                %>
                <li class="nav-item">
                    <a class="nav-link" href="javascript:history.back()"><i class="fas fa-arrow-left me-1"></i> BACK</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= dashboardLink %>"><i class="<%= dashboardIcon %> me-1"></i> <%= dashboardText %></a>
                </li>
                <% } %>

                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/index.jsp">HOME</a>
                </li>

                <li class="nav-item">
                    <a class="nav-link" href="<%= request.getContextPath()%>/browse-designs.jsp">DESIGNS</a>
                </li>

                <% if (userEmail == null) { %>
                <li class="nav-item">
                    <a class="nav-link btn-login-nav" href="<%= request.getContextPath()%>/login.jsp">LOGIN</a>
                </li>
                <% } else { %>
                <li class="nav-item">
                    <a class="nav-link btn-logout-nav" href="<%= request.getContextPath()%>/auth-controller?action=logout">LOGOUT</a>
                </li>
                <% } %>

            </ul>
        </div>
    </div>
</nav>