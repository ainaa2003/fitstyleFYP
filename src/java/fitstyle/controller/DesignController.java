/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package fitstyle.controller;

import fitstyle.dao.DesignDAO;
import java.io.File;
import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;

@WebServlet("/DesignController")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024 * 2, // 2MB
        maxFileSize = 1024 * 1024 * 10, // 10MB
        maxRequestSize = 1024 * 1024 * 50 // 50MB
)
public class DesignController extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        DesignDAO dao = new DesignDAO();

        // Setup folder simpanan gambar
        String uploadPath = getServletContext().getRealPath("/") + "image" + File.separator + "uploads";
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        try {
            if ("addDesign".equals(action)) {
                // 1. Ambil data teks
                String name = request.getParameter("designName");
                String cat = request.getParameter("designCategory");
                String sizeGuideType = request.getParameter("sizeGuideType");
                if (sizeGuideType == null || sizeGuideType.trim().isEmpty()) {
                    sizeGuideType = "Baju Kurung Standard";
                }
                String priceStr = request.getParameter("basePrice");
                double price = Double.parseDouble(priceStr);

                // 2. KEMASKINI NILAI (Jangan letak 'String' atau 'File' lagi di depan)
                uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/baju";
                uploadDir = new File(uploadPath);

                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                // 3. Proses Fail Gambar
                // 1. Ambil fail dari form
                Part filePart = request.getPart("designImage");

// 2. Ambil nama asal fail (Contoh: "baju_kurung.jpg")
                String fileName = filePart.getSubmittedFileName();

// 3. Simpan fail fizikal ke folder "baju" menggunakan nama asal
                filePart.write(uploadPath + File.separator + fileName);

// 4. Simpan ke database (DAO akan terima nama asal fail sahaja)
                boolean success = dao.addDesign(name, cat, sizeGuideType, price, fileName);
                // Simpan fail ke C:/fitstyle_images
                filePart.write(uploadPath + File.separator + fileName);

                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=design&msg=Design added successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?msg=Failed to save to database");
                }

            } else if ("addMaterial".equals(action)) {
                // 1. Ambil data teks
                String materialType = request.getParameter("materialType");
                String materialName = request.getParameter("materialName");
                String cat = request.getParameter("materialCategory");
                String priceStr = request.getParameter("extraPrice");
                double price = Double.parseDouble(priceStr);
                String stockStr = request.getParameter("stockQuantity");
                double stockQuantity = (stockStr != null && !stockStr.trim().isEmpty()) ? Double.parseDouble(stockStr) : 0.00;

                // 2. KEMASKINI NILAI LOKASI FOLDER (Ikut folder baju atau buat folder material)
                // Kalau nak asingkan, tukar hujung tu jadi .../material
                uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/material";
                uploadDir = new File(uploadPath);

                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                // 3. Proses Fail Gambar
                // 1. Ambil fail dari form
                Part filePart = request.getPart("materialImage");

                // 2. Ambil nama asal fail (Contoh: "kain_sutera.jpg")
                String fileName = filePart.getSubmittedFileName();

                // 3. Simpan fail fizikal ke folder menggunakan nama asal
                filePart.write(uploadPath + File.separator + fileName);

                // 4. Simpan ke Database
                // Pastikan DAO addMaterial kau terima parameter mengikut susunan (name, cat, fileName, price)
                boolean success = dao.addMaterial(materialType, materialName, cat, fileName, price, stockQuantity);

                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=material&msg=Material added successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?msg=Failed to save to database");
                }
            } else if ("updateDesign".equals(action)) {
                int designId = Integer.parseInt(request.getParameter("designId"));
                String name = request.getParameter("designName");
                String cat = request.getParameter("designCategory");
                String sizeGuideType = request.getParameter("sizeGuideType");
                if (sizeGuideType == null || sizeGuideType.trim().isEmpty()) {
                    sizeGuideType = "Baju Kurung Standard";
                }
                double price = Double.parseDouble(request.getParameter("basePrice"));
                String fileName = null;

                Part filePart = request.getPart("designImage");
                if (filePart != null && filePart.getSize() > 0 && filePart.getSubmittedFileName() != null && !filePart.getSubmittedFileName().trim().isEmpty()) {
                    uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/baju";
                    uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    fileName = filePart.getSubmittedFileName();
                    filePart.write(uploadPath + File.separator + fileName);
                }

                boolean success = dao.updateDesign(designId, name, cat, sizeGuideType, price, fileName);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=design&msg=Design updated successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=design&msg=Failed to update design");
                }

            } else if ("deleteDesign".equals(action)) {
                int designId = Integer.parseInt(request.getParameter("designId"));
                boolean success = dao.deleteDesign(designId);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=design&msg=Design deleted successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=design&msg=Failed to delete design");
                }

            } else if ("deleteMaterial".equals(action)) {
                int materialId = Integer.parseInt(request.getParameter("materialId"));
                boolean success = dao.deleteMaterial(materialId);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=material&msg=Material deleted successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=material&msg=Failed to delete material");
                }

            } else if ("updateMaterial".equals(action)) {
                int materialId = Integer.parseInt(request.getParameter("materialId"));
                String materialType = request.getParameter("materialType");
                String materialName = request.getParameter("materialName");
                String cat = request.getParameter("materialCategory");
                double price = Double.parseDouble(request.getParameter("extraPrice"));
                String stockStr = request.getParameter("stockQuantity");
                double stockQuantity = (stockStr != null && !stockStr.trim().isEmpty()) ? Double.parseDouble(stockStr) : 0.00;
                String fileName = null;

                Part filePart = request.getPart("materialImage");
                if (filePart != null && filePart.getSize() > 0 && filePart.getSubmittedFileName() != null && !filePart.getSubmittedFileName().trim().isEmpty()) {
                    uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/material";
                    uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    fileName = filePart.getSubmittedFileName();
                    filePart.write(uploadPath + File.separator + fileName);
                }

                boolean success = dao.updateMaterial(materialId, materialType, materialName, cat, fileName, price, stockQuantity);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=material&msg=Material updated successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=material&msg=Failed to update material");
                }

            } else if ("addDecoration".equals(action)) {
                String decorationName = request.getParameter("decorationName");
                String description = request.getParameter("description");
                String decorationType = request.getParameter("decorationType");
                if (decorationType == null || decorationType.trim().isEmpty()) { decorationType = "Other"; }
                double price = Double.parseDouble(request.getParameter("price"));

                uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/decoration";
                uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }

                Part filePart = request.getPart("decorationImage");
                String fileName = filePart.getSubmittedFileName();
                filePart.write(uploadPath + File.separator + fileName);

                boolean success = dao.addDecoration(decorationName, description, decorationType, price, fileName);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Decoration added successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Failed to add decoration");
                }

            } else if ("updateDecoration".equals(action)) {
                int decorationId = Integer.parseInt(request.getParameter("decorationId"));
                String decorationName = request.getParameter("decorationName");
                String description = request.getParameter("description");
                String decorationType = request.getParameter("decorationType");
                if (decorationType == null || decorationType.trim().isEmpty()) { decorationType = "Other"; }
                double price = Double.parseDouble(request.getParameter("price"));
                boolean isActive = request.getParameter("isActive") != null;
                String fileName = null;

                Part filePart = request.getPart("decorationImage");
                if (filePart != null && filePart.getSize() > 0 && filePart.getSubmittedFileName() != null && !filePart.getSubmittedFileName().trim().isEmpty()) {
                    uploadPath = "C:/Users/Acer/Documents/AAAASem 5 FYP/decoration";
                    uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    fileName = filePart.getSubmittedFileName();
                    filePart.write(uploadPath + File.separator + fileName);
                }

                boolean success = dao.updateDecoration(decorationId, decorationName, description, decorationType, price, fileName, isActive);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Decoration updated successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Failed to update decoration");
                }

            } else if ("deleteDecoration".equals(action)) {
                int decorationId = Integer.parseInt(request.getParameter("decorationId"));
                boolean success = dao.deleteDecoration(decorationId);
                if (success) {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Decoration deleted successfully!");
                } else {
                    response.sendRedirect("tailor-dashboard.jsp?section=decoration&msg=Failed to delete decoration");
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("tailor-dashboard.jsp?msg=Error: " + e.getMessage());
        }
    }
}
