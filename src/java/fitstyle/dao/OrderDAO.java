/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package fitstyle.dao;

import fitstyle.util.DBConnection;
import java.sql.*;

public class OrderDAO {

    public int createOrder(int customerId, int designId, String shirtFabric, String skirtFabric,
            String shirtFabricType, String skirtFabricType, double shirtMeterUsed, double skirtMeterUsed,
            String topSize, String bottomSize, String fitPreference,
            String height, String weight, String notes, double totalPrice,
            int decorationId, String decorationName, String decorationArea, String decorationNotes, double decorationPrice) {

        String sql = "INSERT INTO orders (customer_id, design_id, shirt_fabric_name, skirt_fabric_name, "
                + "shirt_fabric_type, skirt_fabric_type, shirt_meter_used, skirt_meter_used, "
                + "top_size, bottom_size, fit_preference, height_cm, weight_kg, special_request, "
                + "total_price, decoration_id, decoration_name, decoration_area, decoration_notes, decoration_price, "
                + "order_status, payment_status, progress_status, stock_deducted) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1, customerId);
            ps.setInt(2, designId);
            ps.setString(3, shirtFabric);
            ps.setString(4, skirtFabric);
            ps.setString(5, shirtFabricType);
            ps.setString(6, skirtFabricType);
            ps.setDouble(7, shirtMeterUsed);
            ps.setDouble(8, skirtMeterUsed);
            ps.setString(9, topSize);
            ps.setString(10, bottomSize);
            ps.setString(11, fitPreference);

            if (height == null || height.trim().isEmpty()) {
                ps.setNull(12, Types.DOUBLE);
            } else {
                ps.setDouble(12, Double.parseDouble(height));
            }

            if (weight == null || weight.trim().isEmpty()) {
                ps.setNull(13, Types.DOUBLE);
            } else {
                ps.setDouble(13, Double.parseDouble(weight));
            }

            ps.setString(14, notes);
            ps.setDouble(15, totalPrice);
            if (decorationId > 0) {
                ps.setInt(16, decorationId);
            } else {
                ps.setNull(16, Types.INTEGER);
            }
            ps.setString(17, decorationName);
            ps.setString(18, decorationArea);
            ps.setString(19, decorationNotes);
            ps.setDouble(20, decorationPrice);
            ps.setString(21, "waiting_for_payment");
            ps.setString(22, "pending");
            ps.setString(23, "pending");
            ps.setBoolean(24, false);

            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        return rs.getInt(1);
                    }
                }
            }
            return 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return 0;
        }
    }
}
