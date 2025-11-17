FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

ARG BLUEMAP_VERSION=5.13
ARG BLUEMAP_CLI_URL="https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v${BLUEMAP_VERSION}/bluemap-${BLUEMAP_VERSION}-cli.jar"
ARG PG_JDBC_VERSION=42.7.8
ARG PG_JDBC_URL="https://github.com/pgjdbc/pgjdbc/releases/download/REL${PG_JDBC_VERSION}/postgresql-${PG_JDBC_VERSION}.jar"

RUN curl -fL "${BLUEMAP_CLI_URL}" -o "/app/bluemap-cli.jar" \
    && curl -fL "${PG_JDBC_URL}" -o "/app/postgresql-driver.jar"

COPY config /app/config

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8100

ENTRYPOINT ["/app/entrypoint.sh"]