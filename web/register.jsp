<%-- 
    Document   : register
    Created on : Jan 18, 2026, 3:57:28 AM
    Author     : Acer
--%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta charset="UTF-8">
        <title>Register | FitStyle</title>
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Poppins:wght@300;400;600&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <style>
            body {
                font-family: 'Poppins', sans-serif;
                background-color: #f4f7f6;
                color: var(--primary);
            }

            .reg-card {
                margin-top: 40px;
                margin-bottom: 50px;
                border: none;
                border-radius: 0;
                box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            }

            .reg-header {
                background-color: var(--primary);
                color: var(--gold);
                padding: 25px;
                text-align: center;
                border-bottom: 4px solid var(--gold);
            }

            .reg-header h3 {
                font-family: 'Playfair Display', serif;
                font-weight: bold;
                margin: 0;
            }

            .form-control {
                border-radius: 0;
                padding: 10px;
                border: 1px solid #ddd;
            }

            .btn-reg {
                background-color: var(--primary);
                color: white;
                border: none;
                border-radius: 0;
                padding: 12px;
                width: 100%;
                font-weight: 600;
                text-transform: uppercase;
                transition: 0.3s;
            }

            .btn-reg:hover {
                background-color: var(--gold);
                color: var(--primary);
            }
            .password-rules div{
                color:#dc3545;
                margin-bottom:4px
            }
            .password-rules div.valid{
                color:#198754;
                font-weight:600
            }
        </style>
    </head>
    <body>

        <%@include file="includes/navbar.jsp" %>

        <div class="container">
            <div class="row justify-content-center">
                <div class="col-md-6">
                    <div class="card reg-card">
                        <div class="reg-header">
                            <h3>Create Account</h3>
                            <p class="text-white-50 small mb-0">Join FitStyle for a bespoke experience</p>
                        </div>
                        <div class="card-body p-4 p-md-5">
                            <%
                                String error = request.getParameter("error");
                                String msg = request.getParameter("msg");
                                if (error != null && !error.trim().isEmpty()) {
                            %>
                            <div class="alert alert-danger"><%= error%></div>
                            <% } else if (msg != null && !msg.trim().isEmpty()) {%>
                            <div class="alert alert-success"><%= msg%></div>
                            <% }%>

                            <form action="auth-controller" method="POST" onsubmit="return validateRegisterPassword();">
                                <input type="hidden" name="action" value="register">

                                <div class="row">
                                    <div class="col-md-12 mb-3">
                                        <label class="small fw-bold">Full Name</label>
                                        <input type="text" name="name" class="form-control" placeholder="Your Name" required>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="small fw-bold">Email</label>
                                        <input type="email" name="email" class="form-control" placeholder="email@example.com" required>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="small fw-bold">Phone Number</label>
                                        <input type="tel" name="phone" class="form-control" placeholder="0123456789" required>
                                    </div>
                                    <div class="col-md-12 mb-4">
                                        <label class="small fw-bold">Password</label>
                                        <div class="input-group">
                                            <input type="password" id="password" name="password" class="form-control" placeholder="Enter Password" required onkeyup="checkPasswordStrength()">
                                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword()">
                                                <i id="eyeIcon" class="fas fa-eye"></i>
                                            </button>
                                        </div>

                                        <small id="strengthText" class="fw-bold d-block mt-2 text-danger">Weak Password</small>

                                        <div class="mt-2 small password-rules" id="passwordRules">
                                            <div id="ruleLength"><i class="fas fa-times-circle"></i> Minimum 8 characters</div>
                                            <div id="ruleUpper"><i class="fas fa-times-circle"></i> At least 1 uppercase letter</div>
                                            <div id="ruleLower"><i class="fas fa-times-circle"></i> At least 1 lowercase letter</div>
                                            <div id="ruleNumber"><i class="fas fa-times-circle"></i> At least 1 number</div>
                                            <div id="ruleSpecial"><i class="fas fa-times-circle"></i> At least 1 special character (@#$%^&*)</div>
                                        </div>
                                    </div>
                                </div>

                                <button type="submit" class="btn-reg">Register Account</button>
                            </form>

                            <div class="text-center mt-4">
                                <p class="small">Already have an account? <a href="login.jsp" style="color:var(--emerald); font-weight:bold; text-decoration:none;">Login Here</a></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script>
            function togglePassword() {
                const password = document.getElementById("password");
                const eye = document.getElementById("eyeIcon");

                if (password.type === "password") {
                    password.type = "text";
                    eye.className = "fas fa-eye-slash";
                } else {
                    password.type = "password";
                    eye.className = "fas fa-eye";
                }
            }

            function updateRule(ruleId, isValid) {
                const rule = document.getElementById(ruleId);
                const icon = rule.querySelector("i");

                if (isValid) {
                    rule.classList.add("valid");
                    icon.className = "fas fa-check-circle";
                } else {
                    rule.classList.remove("valid");
                    icon.className = "fas fa-times-circle";
                }
            }

            function checkPasswordStrength() {
                const pwd = document.getElementById("password").value;

                const hasLength = pwd.length >= 8;
                const hasUpper = /[A-Z]/.test(pwd);
                const hasLower = /[a-z]/.test(pwd);
                const hasNumber = /[0-9]/.test(pwd);
                const hasSpecial = /[@$!%*?&^#_\-]/.test(pwd);

                updateRule("ruleLength", hasLength);
                updateRule("ruleUpper", hasUpper);
                updateRule("ruleLower", hasLower);
                updateRule("ruleNumber", hasNumber);
                updateRule("ruleSpecial", hasSpecial);

                const strengthText = document.getElementById("strengthText");

                if (hasLength && hasUpper && hasLower && hasNumber && hasSpecial) {
                    strengthText.innerHTML = "Strong Password";
                    strengthText.className = "fw-bold d-block mt-2 text-success";
                } else {
                    strengthText.innerHTML = "Weak Password";
                    strengthText.className = "fw-bold d-block mt-2 text-danger";
                }
            }

            function validateRegisterPassword() {
                const pwd = document.getElementById("password").value;
                const pattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&^#_\-]).{8,}$/;

                if (!pattern.test(pwd)) {
                    alert(
                            "Password must contain:\n\n" +
                            "- Minimum 8 characters\n" +
                            "- At least 1 uppercase letter\n" +
                            "- At least 1 lowercase letter\n" +
                            "- At least 1 number\n" +
                            "- At least 1 special character (@#$%^&*)"
                            );
                    return false;
                }

                return true;
            }
        </script>

    </body>
</html>