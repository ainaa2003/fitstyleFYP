/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package fitstyle.model;

/**
 * Model User untuk menyimpan data pengguna sistem FitStyle
 */
public class User {
    private int userId;         // ID Utama (Auto-increment dalam DB)
    private String displayId;   // ID Khas (Cust01, T01, M01)
    private String fullName;
    private String email;
    private String phone;
    private String password;
    private String role;
    private String address;

    // Constructor Kosong (Wajib ada untuk DAO)
    public User() {}

    // Constructor Penuh (Dikemaskini dengan displayId)
    public User(int userId, String displayId, String fullName, String email, String phone, String role, String address) {
        this.userId = userId;
        this.displayId = displayId;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.role = role;
        this.address = address;
    }

    // --- Getter dan Setter ---

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public String getDisplayId() { return displayId; }
    public void setDisplayId(String displayId) { this.displayId = displayId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
}