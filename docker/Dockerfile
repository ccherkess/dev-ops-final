FROM tomcat:9.0

WORKDIR /usr/local/tomcat
RUN rm -rf webapps/*
COPY app.war webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]