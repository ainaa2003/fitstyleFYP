package fitstyle.dao;

import java.sql.*;
import fitstyle.util.DBConnection;
import fitstyle.model.User;

public class UserDAO {

    // 1. Fungsi untuk REGISTER Customer (User Biasa)
    public boolean registerUser(String name, String email, String phone, String password) {
        String sql = "INSERT INTO users (full_name, email, phone, password, role, display_id) VALUES (?, ?, ?, ?, 'customer', ?)";
        
        try (Connection conn = DBConnection.getConnection()) {
            String displayId = generateDisplayId("customer", conn); // Jana ID CustXX
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, name);
                ps.setString(2, email);
                ps.setString(3, phone);
                ps.setString(4, password);
                ps.setString(5, displayId);
                
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // 2. Fungsi untuk Manager daftarkan TAILOR
    public boolean registerTailor(String name, String email, String phone, String password) {
        String sql = "INSERT INTO users (full_name, email, phone, password, role, display_id) VALUES (?, ?, ?, ?, 'tailor', ?)";
        
        try (Connection conn = DBConnection.getConnection()) {
            String displayId = generateDisplayId("tailor", conn); // Jana ID TXX
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, name);
                ps.setString(2, email);
                ps.setString(3, phone);
                ps.setString(4, password);
                ps.setString(5, displayId);
                
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // 3. Fungsi LOGIN yang pulangkan objek User (Sangat penting untuk Session)
    public User login(String email, String password) {
        String sql = "SELECT * FROM users WHERE email = ? AND password = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            
            ps.setString(1, email);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();
            
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_Id"));
                user.setFullName(rs.getString("full_name"));
                user.setEmail(rs.getString("email"));
                user.setRole(rs.getString("role"));
                user.setDisplayId(rs.getString("display_id")); // Pastikan field ini ada di model User.java
                return user;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }


    public User getUserById(int userId) {
        String sql = "SELECT * FROM users WHERE user_Id = ?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                User user = new User();
                user.setUserId(rs.getInt("user_Id"));
                user.setDisplayId(rs.getString("display_id"));
                user.setFullName(rs.getString("full_name"));
                user.setEmail(rs.getString("email"));
                user.setPhone(rs.getString("phone"));
                user.setRole(rs.getString("role"));
                user.setAddress(rs.getString("address"));
                return user;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateProfile(int userId, String fullName, String email, String phone, String address) {
        String sql = "UPDATE users SET full_name=?, email=?, phone=?, address=? WHERE user_Id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fullName);
            ps.setString(2, email);
            ps.setString(3, phone);
            ps.setString(4, address);
            ps.setInt(5, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updatePassword(int userId, String newPassword) {
        String sql = "UPDATE users SET password=? WHERE user_Id=?";
        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, newPassword);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // 4. Logik Penjana ID Automatik (Cust01, T01, M01)
    private String generateDisplayId(String role, Connection conn) throws SQLException {
        String prefix = "";
        if (role.equalsIgnoreCase("customer")) prefix = "Cust";
        else if (role.equalsIgnoreCase("manager")) prefix = "M";
        else if (role.equalsIgnoreCase("tailor")) prefix = "T";

        // Kira jumlah user sedia ada untuk role tersebut
        String sql = "SELECT COUNT(*) FROM users WHERE role = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, role);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                int count = rs.getInt(1) + 1;
                return prefix + String.format("%02d", count);
            }
        }
        return prefix + "01";
    }
}