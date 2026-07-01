/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package fitstyle.controller;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// URL pattern ini yang akan dipanggil oleh tag <img> dalam JSP
@WebServlet(name = "ImageDisplayController", urlPatterns = {"/displayImage"})
public class ImageDisplayController extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String fileName = request.getParameter("name");
        String type = request.getParameter("type"); // Tambah parameter type
        
        // Path asas
        String basePath = "C:\\Users\\Acer\\Documents\\AAAASem 5 FYP\\";
        String uploadPath;

        // Tentukan folder berdasarkan type
        if ("material".equals(type)) {
            uploadPath = basePath + "material";
        } else if ("decoration".equals(type)) {
            uploadPath = basePath + "decoration";
        } else {
            uploadPath = basePath + "baju"; // Default folder baju (untuk design)
        }
        
        File file = new File(uploadPath, fileName);

        // If old/static images are stored inside web/image, use them as fallback.
        if ((fileName != null) && (!file.exists() || file.isDirectory())) {
            File webImage = new File(getServletContext().getRealPath("/image"), fileName);
            if (webImage.exists() && !webImage.isDirectory()) {
                file = webImage;
            }
        }

        // DEBUG
        System.out.println("DEBUG: Mencari fail di -> " + file.getAbsolutePath());

        if (file.exists() && !file.isDirectory()) {
            String contentType = getServletContext().getMimeType(fileName);
            if (contentType == null) contentType = "image/jpeg";
            
            response.setContentType(contentType);
            Files.copy(file.toPath(), response.getOutputStream());
        } else {
            response.sendRedirect("https://via.placeholder.com/400x500?text=Fail+Tiada");
        }
    }
}