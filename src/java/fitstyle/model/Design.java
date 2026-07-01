/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package fitstyle.model;

public class Design {
    private int designId;
    private String designName;
    private String category; // Style category
    private String sizeGuideType;
    private double basePrice;
    private String imageName;

    public Design() {}

    public Design(int designId, String designName, String category, double basePrice, String imageName) {
        this.designId = designId;
        this.designName = designName;
        this.category = category;
        this.sizeGuideType = "Baju Kurung Standard";
        this.basePrice = basePrice;
        this.imageName = imageName;
    }

    // Getter & Setter
    public int getDesignId() { return designId; }
    public void setDesignId(int designId) { this.designId = designId; }

    public String getDesignName() { return designName; }
    public void setDesignName(String designName) { this.designName = designName; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getSizeGuideType() { return sizeGuideType; }
    public void setSizeGuideType(String sizeGuideType) { this.sizeGuideType = sizeGuideType; }

    public double getBasePrice() { return basePrice; }
    public void setBasePrice(double basePrice) { this.basePrice = basePrice; }

    public String getImageName() { return imageName; }
    public void setImageName(String imageName) { this.imageName = imageName; }
}