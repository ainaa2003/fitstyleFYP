/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package fitstyle.dao;

import fitstyle.model.Design;
import fitstyle.model.Material;
import fitstyle.util.DBConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class DesignDAO {

    // Simpan Design Baru (Baju)
    public boolean addDesign(String name, String cat, double price, String img) {
        return addDesign(name, cat, "Baju Kurung Standard", price, img);
    }

    public boolean addDesign(String name, String cat, String sizeGuideType, double price, String img) {
        String sql = "INSERT INTO designs (design_name, category, size_guide_type, base_price, image_name) VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, name);
            ps.setString(2, cat);
            ps.setString(3, sizeGuideType);
            ps.setDouble(4, price);
            ps.setString(5, img);

            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error dalam addDesign: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    // Simpan Material Baru (Kain)
    // Kemaskini method addMaterial dalam DesignDAO.java
    public boolean addMaterial(String materialType, String materialName, String cat, String fileName, double price) {
        return addMaterial(materialType, materialName, cat, fileName, price, 0.00);
    }

    public boolean addMaterial(String materialType, String materialName, String cat, String fileName, double price, double stockQuantity) {
        String sql = "INSERT INTO materials (material_type, material_name, category, image_name, extra_price, stock_quantity) VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, materialType);
            ps.setString(2, materialName);
            ps.setString(3, cat);
            ps.setString(4, fileName);
            ps.setDouble(5, price);
            ps.setDouble(6, stockQuantity);

            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<Material> getAllMaterials() {
        List<Material> list = new ArrayList<>();
        String sql = "SELECT * FROM materials ORDER BY material_id DESC";
        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Material(
                        rs.getInt("material_id"),
                        rs.getString("material_type"),
                        rs.getString("material_name"),
                        rs.getString("category"),
                        rs.getString("image_name"),
                        rs.getDouble("extra_price"),
                        rs.getDouble("stock_quantity")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Design> getAllDesigns() {
        List<Design> list = new ArrayList<>();
        // Kita guna query ni untuk tarik semua design
        String sql = "SELECT * FROM designs ORDER BY design_id DESC";

        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Design d = new Design();
                d.setDesignId(rs.getInt("design_id"));
                d.setDesignName(rs.getString("design_name"));
                d.setCategory(rs.getString("category"));
                try {
                    d.setSizeGuideType(rs.getString("size_guide_type"));
                } catch (Exception ignore) {
                    d.setSizeGuideType("Baju Kurung Standard");
                }
                d.setBasePrice(rs.getDouble("base_price"));
                d.setImageName(rs.getString("image_name"));

                list.add(d);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<String> getAllCategories() {
        List<String> categories = new ArrayList<>();
        String sql = "SELECT DISTINCT category FROM designs"; // DISTINCT supaya tak double

        try (Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                categories.add(rs.getString("category"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return categories;
    }

    public boolean updateDesign(int designId, String name, String cat, double price, String img) {
        return updateDesign(designId, name, cat, "Baju Kurung Standard", price, img);
    }

    public boolean updateDesign(int designId, String name, String cat, String sizeGuideType, double price, String img) {
        String sql;
        boolean hasNewImage = img != null && !img.trim().isEmpty();

        if (hasNewImage) {
            sql = "UPDATE designs SET design_name=?, category=?, size_guide_type=?, base_price=?, image_name=? WHERE design_id=?";
        } else {
            sql = "UPDATE designs SET design_name=?, category=?, size_guide_type=?, base_price=? WHERE design_id=?";
        }

        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, cat);
            ps.setString(3, sizeGuideType);
            ps.setDouble(4, price);
            if (hasNewImage) {
                ps.setString(5, img);
                ps.setInt(6, designId);
            } else {
                ps.setInt(5, designId);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in updateDesign: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateMaterial(int materialId, String materialType, String materialName, String cat, String fileName, double price) {
        return updateMaterial(materialId, materialType, materialName, cat, fileName, price, 0.00);
    }

    public boolean updateMaterial(int materialId, String materialType, String materialName, String cat, String fileName, double price, double stockQuantity) {
        String sql;
        boolean hasNewImage = fileName != null && !fileName.trim().isEmpty();

        if (hasNewImage) {
            sql = "UPDATE materials SET material_type=?, material_name=?, category=?, image_name=?, extra_price=?, stock_quantity=? WHERE material_id=?";
        } else {
            sql = "UPDATE materials SET material_type=?, material_name=?, category=?, extra_price=?, stock_quantity=? WHERE material_id=?";
        }

        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, materialType);
            ps.setString(2, materialName);
            ps.setString(3, cat);
            if (hasNewImage) {
                ps.setString(4, fileName);
                ps.setDouble(5, price);
                ps.setDouble(6, stockQuantity);
                ps.setInt(7, materialId);
            } else {
                ps.setDouble(4, price);
                ps.setDouble(5, stockQuantity);
                ps.setInt(6, materialId);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in updateMaterial: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteDesign(int designId) {
        String sql = "DELETE FROM designs WHERE design_id=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, designId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in deleteDesign: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteMaterial(int materialId) {
        String sql = "DELETE FROM materials WHERE material_id=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, materialId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in deleteMaterial: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }


    public boolean addDecoration(String name, String description, String decorationType, double price, String imageName) {
        String sql = "INSERT INTO decorations (decoration_name, description, decoration_type, price, image_name, is_active) VALUES (?, ?, ?, ?, ?, 1)";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, description);
            ps.setString(3, decorationType);
            ps.setDouble(4, price);
            ps.setString(5, imageName);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in addDecoration: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateDecoration(int decorationId, String name, String description, String decorationType, double price, String imageName, boolean isActive) {
        String sql;
        boolean hasNewImage = imageName != null && !imageName.trim().isEmpty();
        if (hasNewImage) {
            sql = "UPDATE decorations SET decoration_name=?, description=?, decoration_type=?, price=?, image_name=?, is_active=? WHERE decoration_id=?";
        } else {
            sql = "UPDATE decorations SET decoration_name=?, description=?, decoration_type=?, price=?, is_active=? WHERE decoration_id=?";
        }
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, description);
            ps.setString(3, decorationType);
            ps.setDouble(4, price);
            if (hasNewImage) {
                ps.setString(5, imageName);
                ps.setBoolean(6, isActive);
                ps.setInt(7, decorationId);
            } else {
                ps.setBoolean(5, isActive);
                ps.setInt(6, decorationId);
            }
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in updateDecoration: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteDecoration(int decorationId) {
        String sql = "DELETE FROM decorations WHERE decoration_id=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, decorationId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error in deleteDecoration: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

}
