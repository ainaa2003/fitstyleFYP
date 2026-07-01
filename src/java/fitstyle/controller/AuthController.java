package fitstyle.controller;

import fitstyle.dao.UserDAO;
import fitstyle.model.User;
import java.io.IOException;
import java.net.URLEncoder;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "AuthController", urlPatterns = {"/auth-controller"})
public class AuthController extends HttpServlet {

    private boolean isStrongPassword(String password) {
        if (password == null) {
            return false;
        }
        String regex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&^#_\\-]).{8,}$";
        return password.matches(regex);
    }

    private String encode(String value) throws IOException {
        return URLEncoder.encode(value, "UTF-8");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        UserDAO userDAO = new UserDAO();
        HttpSession session = request.getSession();

        if ("register".equals(action)) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String pass = request.getParameter("password");

            if (!isStrongPassword(pass)) {
                response.sendRedirect("register.jsp?error=" + encode("Password must contain at least 8 characters, one uppercase letter, one lowercase letter, one number and one special character."));
                return;
            }

            boolean isRegistered = userDAO.registerUser(name, email, phone, pass);

            if (isRegistered) {
                response.sendRedirect("login.jsp?msg=Akaun berjaya didaftar! Sila log masuk.");
            } else {
                response.sendRedirect("register.jsp?error=Gagal mendaftar akaun.");
            }

        } else if ("registerTailor".equals(action)) {
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String pass = request.getParameter("password");

            boolean isRegistered = userDAO.registerTailor(name, email, phone, pass);

            if (isRegistered) {
                response.sendRedirect("manager-dashboard.jsp?msg=Tailor baru berjaya didaftarkan!");
            } else {
                response.sendRedirect("manager-dashboard.jsp?error=Gagal mendaftar tailor.");
            }

        } else if ("login".equals(action)) {
            String email = request.getParameter("email");
            String pass = request.getParameter("password");

            User user = userDAO.login(email, pass);

            if (user != null) {
                session.setAttribute("userId", user.getUserId());
                session.setAttribute("userEmail", user.getEmail());
                session.setAttribute("userRole", user.getRole());
                session.setAttribute("userName", user.getFullName());

                String pendingOrder = (String) session.getAttribute("pendingDesignID");
                String pendingPrice = (String) session.getAttribute("pendingBasePrice");

                if (pendingOrder != null) {
                    session.removeAttribute("pendingDesignID");
                    session.removeAttribute("pendingBasePrice");
                    response.sendRedirect("OrderController?action=checkLogin&designID=" + pendingOrder + "&basePrice=" + pendingPrice);
                } else {
                    if ("manager".equals(user.getRole())) {
                        response.sendRedirect("manager-dashboard.jsp");
                    } else if ("tailor".equals(user.getRole())) {
                        response.sendRedirect("tailor-dashboard.jsp");
                    } else {
                        response.sendRedirect("customer-dashboard.jsp");
                    }
                }
            } else {
                response.sendRedirect("login.jsp?error=Email atau Password salah!");
            }

        } else if ("updateProfile".equals(action)) {
            Object uid = session.getAttribute("userId");

            if (uid == null) {
                response.sendRedirect("login.jsp?msg=Please login first");
                return;
            }

            int userId = Integer.parseInt(uid.toString());
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String address = request.getParameter("address");
            String newPassword = request.getParameter("newPassword");

            boolean ok = userDAO.updateProfile(userId, name, email, phone, address);

            if (newPassword != null && !newPassword.trim().isEmpty()) {
                ok = ok && userDAO.updatePassword(userId, newPassword);
            }

            if (ok) {
                session.setAttribute("userEmail", email);
                session.setAttribute("userName", name);
                response.sendRedirect("profile.jsp?msg=Profile updated successfully!");
            } else {
                response.sendRedirect("profile.jsp?error=Failed to update profile.");
            }
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        if ("logout".equals(action)) {
            HttpSession session = request.getSession();
            session.invalidate();
            response.sendRedirect("index.jsp?msg=Anda telah log keluar.");
        }
    }
}