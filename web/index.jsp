<%-- 
    Document    : index
    Created on : Jan 17, 2026, 7:50:11 PM
    Author      : Acer
--%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>FitStyle | Online Custom Tailoring</title>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

        <style>
            <%
                String role = (String) session.getAttribute("userRole");

                String primary = "#043927";         // default/customer navbar emerald
                String secondary = "#D4AF37";       // gold
                String softBg = "#6A927A";
                String heroOverlay = "rgba(15, 55, 35, 0.52)";

                if ("tailor".equals(role)) {
                    primary = "#355FA0";
                    softBg = "#5E82BD";
                    heroOverlay = "rgba(20, 35, 70, 0.55)";
                }
            %>

            :root {
                --primary: <%= primary%>;
                --secondary: <%= secondary%>;
                --soft-bg: <%= softBg%>;
                --hero-overlay: <%= heroOverlay%>;
                --light-gold: #f1d592;
                --white: #ffffff;
            }

            body {
                font-family: 'Poppins', sans-serif;
                background-color: var(--soft-bg);
                color: var(--primary);
            }

            .hero-section {
                background: linear-gradient(
                    var(--hero-overlay),
                    var(--hero-overlay)
                    ),
                    url('<%= request.getContextPath()%>/image/background.png');

                background-size: cover;
                background-position: center;
                background-repeat: no-repeat;

                min-height: 100vh;   /* ⬅️ tukar dari height:90vh */
                display: flex;
                align-items: center;
                justify-content: center;
                text-align: center;

                color: var(--white);
                border-bottom: 10px solid var(--secondary);
            }

            .hero-content h1 {
                font-family: 'Playfair Display', serif;
                font-size: 4rem;
                margin-bottom: 20px;
                text-transform: uppercase;
                letter-spacing: 5px;
            }

            .hero-content h1 span {
                color: var(--secondary);
            }

            .hero-content p {
                font-size: 1.2rem;
                font-weight: 300;
                max-width: 700px;
                margin: 0 auto 30px;
                color: var(--light-gold);
            }

            .btn-get-started {
                background-color: var(--secondary);
                color: var(--primary);
                padding: 15px 40px;
                font-size: 18px;
                font-weight: 600;
                border-radius: 0;
                border: 2px solid var(--secondary);
                transition: 0.4s;
                text-transform: uppercase;
                letter-spacing: 2px;
                text-decoration: none;
            }

            .btn-get-started:hover {
                background-color: transparent;
                color: var(--secondary);
                border: 2px solid var(--secondary);
            }

            .feature-box {
                padding: 40px 20px;
                border: 1px solid #eee;
                transition: 0.3s;
            }

            .feature-box:hover {
                transform: translateY(-10px);
                border-color: var(--secondary);
                background-color: #f9fdfc;
                cursor: default;
            }

            .icon-gold {
                color: var(--secondary);
                font-size: 50px;
                margin-bottom: 20px;
                display: block;
            }
        </style>
    </head>
    <body>

        <%@include file="includes/navbar.jsp" %>

        <section class="hero-section">
            <div class="container">
                <div class="hero-content">
                    <h1>Perfect <span>Fit</span> Begins With <span>Style</span></h1>
                    <p>Fitstyle blends traditional craftsmanship with modern technology to create seamless tailoring experience.</p>
                    <p>From Baju Melayu to Baju Kurung, every outfit is designed with style, comfort and a perfect fit in mind.</p>
                    <a href="browse-designs.jsp" class="btn-get-started">Get Started</a>
                </div>
            </div>
        </section>

        <section class="container my-5 py-5 text-center">
            <div class="row">
                <div class="col-md-4 feature-box">
                    <div class="icon-gold">
                        <i class="fas fa-cut"></i>
                    </div>
                    <h4>Custom Design</h4>
                    <p>Choose from our catalog or upload your own unique creation.</p>
                </div>

                <div class="col-md-4 feature-box">
                    <div class="icon-gold">
                        <i class="fas fa-ruler-combined"></i>
                    </div>
                    <h4>Perfect Fit</h4>
                    <p>Precise body measurements for all-day comfort.</p>
                </div>

                <div class="col-md-4 feature-box">
                    <div class="icon-gold">
                        <i class="fas fa-credit-card"></i>
                    </div>
                    <h4>Easy Payment</h4>
                    <p>Simple and secure deposit payments via Toyyibpay.</p>
                </div>
            </div>
        </section>

        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>