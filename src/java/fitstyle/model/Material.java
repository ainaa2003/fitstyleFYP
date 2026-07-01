/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package fitstyle.model;

public class Material {
    private int materialId;
    private String materialType;
    private String materialName;
    private String category; // Lelaki / Perempuan
    private String imageName;
    private double extraPrice;
    private double stockQuantity;

    public Material() {}

    public Material(int materialId, String materialName, String category, String imageName, double extraPrice) {
        this.materialId = materialId;
        this.materialName = materialName;
        this.category = category;
        this.imageName = imageName;
        this.extraPrice = extraPrice;
        this.stockQuantity = 0.00;
    }

    public Material(int materialId, String materialType, String materialName, String category, String imageName, double extraPrice) {
        this.materialId = materialId;
        this.materialType = materialType;
        this.materialName = materialName;
        this.category = category;
        this.imageName = imageName;
        this.extraPrice = extraPrice;
        this.stockQuantity = 0.00;
    }

    public Material(int materialId, String materialType, String materialName, String category, String imageName, double extraPrice, double stockQuantity) {
        this.materialId = materialId;
        this.materialType = materialType;
        this.materialName = materialName;
        this.category = category;
        this.imageName = imageName;
        this.extraPrice = extraPrice;
        this.stockQuantity = stockQuantity;
    }

    // Getter & Setter
    public int getMaterialId() { return materialId; }
    public void setMaterialId(int materialId) { this.materialId = materialId; }

    public String getMaterialType() { return materialType; }
    public void setMaterialType(String materialType) { this.materialType = materialType; }

    public String getMaterialName() { return materialName; }
    public void setMaterialName(String materialName) { this.materialName = materialName; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getImageName() { return imageName; }
    public void setImageName(String imageName) { this.imageName = imageName; }

    public double getExtraPrice() { return extraPrice; }
    public void setExtraPrice(double extraPrice) { this.extraPrice = extraPrice; }

    public double getStockQuantity() { return stockQuantity; }
    public void setStockQuantity(double stockQuantity) { this.stockQuantity = stockQuantity; }
}