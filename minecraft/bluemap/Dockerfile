FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Fetch the latest version of Bluemap
RUN curl -s https://api.github.com/repos/BlueMap-Minecraft/BlueMap/releases/latest \
    | grep "browser_download_url.*cli.jar" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - -O /app/cli.jar

# Fetch the latest version of the PostgreSQL JDBC driver
RUN curl -s https://api.github.com/repos/pgjdbc/pgjdbc/releases/latest \
    | grep "browser_download_url.*.jar" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - -O /app/pgjdbc.jar  

COPY ./config ./config

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 8100

ENTRYPOINT ["entrypoint.sh"]
