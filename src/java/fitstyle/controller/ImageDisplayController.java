/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package fitstyle.controller;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

// URL pattern ini yang akan dipanggil oleh tag <img> dalam JSP
@WebServlet(name = "ImageDisplayController", urlPatterns = {"/displayImage"})
public class ImageDisplayController extends HttpServlet {

    private String cleanFileName(String fileName) {
        if (fileName == null) {
            return "";
        }

        fileName = fileName.replace("\\", "/");
        fileName = Paths.get(fileName).getFileName().toString();

        return fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
    }

    private String getUploadBasePath() {
        String baseUploadDir = System.getenv("FITSTYLE_UPLOAD_DIR");

        if (baseUploadDir == null || baseUploadDir.trim().isEmpty()) {
            baseUploadDir = System.getProperty("java.io.tmpdir") + File.separator + "fitstyle_uploads";
        }

        return baseUploadDir;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String originalName = request.getParameter("name");
        String fileName = cleanFileName(originalName);
        String type = request.getParameter("type");

        String folderName;
        if ("material".equals(type)) {
            folderName = "material";
        } else if ("decoration".equals(type)) {
            folderName = "decoration";
        } else {
            folderName = "baju";
        }

        File file = new File(getUploadBasePath() + File.separator + folderName, fileName);

        // Fallback 1: old/static images inside web/image
        if (!file.exists() || file.isDirectory()) {
            File webImage = new File(getServletContext().getRealPath("/image"), fileName);
            if (webImage.exists() && !webImage.isDirectory()) {
                file = webImage;
            }
        }

        // Fallback 2: uploaded images if stored inside web/image/uploads/<folder>
        if (!file.exists() || file.isDirectory()) {
            File webUploadImage = new File(getServletContext().getRealPath("/image/uploads/" + folderName), fileName);
            if (webUploadImage.exists() && !webUploadImage.isDirectory()) {
                file = webUploadImage;
            }
        }

        // Fallback 3: look in all supported upload folders
        if (!file.exists() || file.isDirectory()) {
            String[] folders = {"baju", "material", "decoration"};
            for (String folder : folders) {
                File possibleFile = new File(getUploadBasePath() + File.separator + folder, fileName);
                if (possibleFile.exists() && !possibleFile.isDirectory()) {
                    file = possibleFile;
                    break;
                }
            }
        }

        System.out.println("DEBUG: Mencari fail di -> " + file.getAbsolutePath());

        if (file.exists() && !file.isDirectory()) {
            String contentType = getServletContext().getMimeType(fileName);
            if (contentType == null) {
                contentType = "image/jpeg";
            }

            response.setContentType(contentType);
            Files.copy(file.toPath(), response.getOutputStream());
        } else {
            response.sendRedirect("https://via.placeholder.com/400x500?text=Image+Not+Found");
        }
    }
}
