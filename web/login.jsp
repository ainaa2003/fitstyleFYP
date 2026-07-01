<%-- 
    Document   : login
    Created on : Jan 18, 2026, 3:56:39 AM
    Author     : Acer
--%>
<%
    if (session.getAttribute("userEmail") != null) {
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Login | FitStyle</title>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="<%= request.getContextPath()%>/css/bootstrap-local.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            body {
                font-family: 'Poppins', sans-serif;
                background-color: #f4f7f6;
                color: var(--primary);
            }

            .login-card {
                margin-top: 60px;
                border: none;
                border-radius: 0;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                overflow: hidden;
            }

            .login-header {
                background-color: var(--primary);
                color: var(--gold);
                padding: 30px;
                text-align: center;
                border-bottom: 4px solid var(--gold);
            }

            .login-header h3 {
                font-family: 'Playfair Display', serif;
                font-weight: bold;
                margin: 0;
            }

            .form-control {
                border-radius: 0;
                padding: 12px;
                border: 1px solid #ddd;
            }

            .form-control:focus {
                border-color: var(--gold);
                box-shadow: none;
            }

            .btn-login {
                background-color: var(--primary);
                color: white;
                border: none;
                border-radius: 0;
                padding: 12px;
                width: 100%;
                font-weight: 600;
                text-transform: uppercase;
                letter-spacing: 1px;
                transition: 0.3s;
            }

            .btn-login:hover {
                background-color: var(--gold);
                color: var(--primary);
            }

            .register-link {
                color: var(--primary);
                text-decoration: none;
                font-weight: 600;
                transition: 0.3s;
            }

            .register-link:hover {
                color: var(--gold);
            }
        </style>
    </head>
    <body>

        <%@include file="includes/navbar.jsp" %>

        <div class="container">
            <div class="row justify-content-center">
                <div class="col-md-5">
                    <div class="card login-card">
                        <div class="login-header">
                            <h3>Welcome Back</h3>
                            <p class="text-white-50 small mb-0">Sign in to continue your tailoring journey</p>
                        </div>
                        <div class="card-body p-4 p-md-5">

                            <% String msg = request.getParameter("msg");
                            if (msg != null) {%>
                            <div class="alert alert-info small"><i class="fas fa-info-circle me-2"></i> <%= msg%></div>
                            <% }%>

                            <form action="auth-controller" method="POST">
                                <input type="hidden" name="action" value="login">
                                <div class="mb-3">
                                    <label class="small fw-bold">Email Address</label>
                                    <input type="email" name="email" class="form-control" placeholder="name@example.com" required>
                                </div>
                                <div class="mb-4">
                                    <label class="small fw-bold">Password</label>
                                    <input type="password" name="password" class="form-control" placeholder="Enter password" required>
                                </div>
                                <button type="submit" class="btn-login">Login</button>
                            </form>

                            <div class="text-center mt-4">
                                <p class="small">Don't have an account? <a href="register.jsp" class="register-link">Register Now</a></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </body>
</html>