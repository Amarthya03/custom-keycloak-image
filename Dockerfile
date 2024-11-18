# ? Installing maven using dnf 
# ? Ensure that Java version is compatible with Keycloak
FROM registry.access.redhat.com/ubi9 AS ubi-micro-build
RUN mkdir -p /mnt/rootfs
RUN dnf install --installroot /mnt/rootfs maven java-21-openjdk-devel --releasever 9 --setopt install_weak_deps=false --nodocs -y && \
    dnf --installroot /mnt/rootfs clean all && \
    rpm --root /mnt/rootfs -e --nodeps setup

FROM quay.io/keycloak/keycloak:25.0.6
COPY --from=ubi-micro-build /mnt/rootfs /

# Set environment variables required for Keycloak
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV KEYCLOAK_USER=admin
ENV KEYCLOAK_PASSWORD=admin

# Install Maven to build dependencies
# RUN microdnf install -y maven

# Copy your custom pom.xml file into the container
COPY pom.xml /workspace/

# Download dependencies and create a custom JAR with them
WORKDIR /workspace
RUN mvn dependency:copy-dependencies -DoutputDirectory=/opt/keycloak/providers

# Clean up Maven and unnecessary files
# RUN dnf remove -y maven && dnf clean all

# Set the entrypoint to start Keycloak
# ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--spi-theme-static-max-age=-1", "--spi-theme-cache-themes=false", "--spi-theme-cache-templates=false"]

