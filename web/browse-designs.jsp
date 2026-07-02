<%-- 
    Document   : browse-designs
    Created on : Jan 19, 2026, 2:33:25 AM
    Author     : Acer
--%>

<%@page import="fitstyle.model.Design"%>
<%@page import="java.util.List"%>
<%@page import="fitstyle.dao.DesignDAO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<%
    DesignDAO dao = new DesignDAO();
    List<Design> designs = dao.getAllDesigns();
    request.setAttribute("designs", designs);

    List<String> categories = dao.getAllCategories();
    request.setAttribute("categories", categories);

    String currentRole = (String) session.getAttribute("userRole");
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Katalog Rekaan | FitStyle</title>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            body {
                font-family: 'Poppins', sans-serif;
                background-color: #f8f9fa;
                color: var(--primary);
            }

            .page-header {
                padding: 40px 0;
                text-align: center;
                border-bottom: 1px solid #eee;
            }

            .btn-filter {
                background: transparent;
                border: 2px solid var(--primary);
                color: var(--primary);
                padding: 8px 25px;
                margin: 5px;
                font-weight: 600;
                border-radius: 0;
                text-transform: uppercase;
                font-size: 13px;
                transition: 0.3s;
            }

            .btn-filter.active,
            .btn-filter:hover {
                background: var(--primary);
                color: var(--gold);
            }

            .design-card {
                background: white;
                border: none;
                transition: 0.4s;
                margin-bottom: 30px;
                box-shadow: 0 5px 15px rgba(0,0,0,0.05);
                height: 100%;
                display: flex;
                flex-direction: column;
            }

            .design-img-container {
                height: 350px;
                overflow: hidden;
                background: #f0f0f0;
                position: relative;
            }

            .design-img-container img {
                width: 100%;
                height: 100%;
                object-fit: cover;
                transition: 0.6s;
            }

            .design-card:hover img {
                transform: scale(1.05);
            }

            .card-body {
                padding: 20px;
                text-align: center;
                border: 1px solid #eee;
                border-top: none;
                flex-grow: 1;
            }

            .design-title {
                font-family: 'Playfair Display', serif;
                font-size: 1.2rem;
                font-weight: bold;
                margin-bottom: 5px;
                color: var(--primary);
            }

            .design-price {
                color: var(--gold);
                font-weight: 700;
                margin-bottom: 15px;
                font-size: 1.1rem;
            }

            .btn-order {
                background-color: var(--primary);
                color: white;
                border-radius: 0;
                padding: 10px;
                width: 100%;
                text-decoration: none;
                display: block;
                font-weight: 600;
                text-transform: uppercase;
                transition: 0.3s;
            }

            .btn-order:hover {
                background-color: var(--gold);
                color: var(--primary);
            }
        </style>
    </head>
    <body>

        <jsp:include page="includes/navbar.jsp" />

        <header class="page-header"
                style="background: linear-gradient(135deg, var(--primary) 0%, var(--primary-hover) 100%); color: white;">

            <div class="container py-4">
                <h2 style="color: var(--gold);">E-Katalog FitStyle</h2>
                <p class="text-light">Choose your favorite design to start your order.</p>

                <div class="row justify-content-center mt-4">
                    <div class="col-md-6">
                        <div class="input-group mb-3">

                            <input type="text" id="searchInput" class="form-control"
                                   placeholder="Search for outfit name"
                                   style="border-radius: 0;">

                            <button class="btn"
                                    style="background: var(--gold); color: var(--primary); border-radius: 0;"
                                    type="button">
                                <i class="fas fa-search"></i>
                            </button>

                        </div>
                    </div>
                </div>
            </div>
        </header>

        <div class="container mt-4">
            <% if ("tailor_preview_only".equals(request.getParameter("msg"))) { %>
            <div class="alert alert-warning text-center">
                <i class="fas fa-info-circle me-1"></i>
                Tailor/Owner can preview designs only. Customer orders must be placed using a customer account.
            </div>
            <% } %>
            <div class="filter-container text-center mb-5">
                <button class="btn-filter active" onclick="filterSelection('all')">All Design</button>
                <c:forEach items="${categories}" var="cat">
                    <c:set var="cleanCat" value="${fn:replace(cat, ' ', '-')}" />
                    <button class="btn-filter" onclick="filterSelection('${cleanCat}')">
                        <c:out value="${cat}" />
                    </button>
                </c:forEach>
            </div>

            <div class="row" id="designGrid">
                <c:forEach items="${designs}" var="d">
                    <%-- Tukar jarak kategori untuk class HTML --%>
                    <c:set var="cleanCategory" value="${fn:replace(d.category, ' ', '-')}" />

                    <div class="col-md-3 filter-item ${cleanCategory}" data-name="${d.designName}">
                        <div class="design-card">
                            <div class="design-img-container">
                                <%-- Guna imageName ikut Model kau --%>
                                <img src="displayImage?name=${d.imageName}" 
                                     onerror="this.src='https://via.placeholder.com/400x500?text=Gambar+Tiada'">
                            </div>
                            <div class="card-body">
                                <div class="design-title"><c:out value="${d.designName}"/></div>
                                <div class="small text-muted mb-2"><c:out value="${d.category}"/></div>

                                <%-- Guna basePrice ikut Model kau supaya tak keluar 'RM null' --%>
                                <div class="design-price">Sewing Wages: RM <c:out value="${d.basePrice}"/></div>

                                <c:choose>
                                    <c:when test="${empty sessionScope.userEmail}">
                                        <a href="login.jsp" class="btn-order">Order Now</a>
                                    </c:when>
                                    <c:when test="${sessionScope.userRole eq 'tailor'}">
                                        <a href="tailor-dashboard.jsp?section=design" class="btn-order" style="background:#D4AF37; color:#043927;">
                                            Manage Design
                                        </a>
                                        <div class="small text-muted mt-2">Preview only for tailor/owner</div>
                                    </c:when>
                                    <c:otherwise>
                                        <%-- Hantar designId dan basePrice ke order-form --%>
                                        <a href="order-form.jsp?designID=${d.designId}&basePrice=${d.basePrice}" class="btn-order">
                                            Order Now
                                        </a>
                                    </c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </div>

        <script>
            function filterSelection(c) {
                let x = document.getElementsByClassName("filter-item");
                if (c == "all")
                    c = "";
                for (let i = 0; i < x.length; i++) {
                    x[i].style.display = "none";
                    if (c == "" || x[i].classList.contains(c)) {
                        x[i].style.display = "block";
                    }
                }
                let btns = document.getElementsByClassName("btn-filter");
                for (let j = 0; j < btns.length; j++) {
                    btns[j].classList.remove("active");
                }
                if (event)
                    event.currentTarget.classList.add("active");
            }

            document.getElementById('searchInput').addEventListener('keyup', function () {
                let filter = this.value.toLowerCase();
                let items = document.querySelectorAll('.filter-item');
                items.forEach(item => {
                    let text = item.getAttribute('data-name').toLowerCase();
                    item.style.display = text.includes(filter) ? "" : "none";
                });
            });
        </script>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>