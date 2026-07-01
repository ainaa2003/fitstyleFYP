FROM tomcat:9.0-jdk17-temurin

# Deploy the system as ROOT so Railway link opens directly without /Fitstyle_Shop
COPY dist/Fitstyle_Shop.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
