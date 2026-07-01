/*
 * FitStyle database connection helper.
 * Works on local NetBeans/MySQL and Railway MySQL deployment.
 */
package fitstyle.util;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {

    private static String getEnvOrDefault(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value == null || value.trim().isEmpty()) ? defaultValue : value.trim();
    }

    public static Connection getConnection() {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            String railwayUrl = System.getenv("DATABASE_URL");
            String host = getEnvOrDefault("MYSQLHOST", "localhost");
            String port = getEnvOrDefault("MYSQLPORT", "3306");
            String database = getEnvOrDefault("MYSQLDATABASE", "fitstyle_db");
            String user = getEnvOrDefault("MYSQLUSER", "root");
            String password = getEnvOrDefault("MYSQLPASSWORD", "");

            String url;
            if (railwayUrl != null && railwayUrl.startsWith("mysql://")) {
                // Railway sometimes provides DATABASE_URL in mysql://user:pass@host:port/db format.
                java.net.URI uri = new java.net.URI(railwayUrl);
                String userInfo = uri.getUserInfo();
                if (userInfo != null && userInfo.contains(":")) {
                    String[] parts = userInfo.split(":", 2);
                    user = java.net.URLDecoder.decode(parts[0], "UTF-8");
                    password = java.net.URLDecoder.decode(parts[1], "UTF-8");
                }
                host = uri.getHost();
                port = String.valueOf(uri.getPort());
                database = uri.getPath().replaceFirst("/", "");
            }

            url = "jdbc:mysql://" + host + ":" + port + "/" + database
                    + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";

            conn = DriverManager.getConnection(url, user, password);
            System.out.println("Database connected successfully!");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return conn;
    }
}
