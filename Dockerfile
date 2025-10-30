# Download stage - fetch the helios binary
FROM ubuntu:24.04 AS downloader

ARG HELIOS_VERSION
ARG TARGETARCH

# Install curl in a single layer and download helios
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    REPO="a16z/helios" && \
    if [ -z "$HELIOS_VERSION" ] || [ "$HELIOS_VERSION" = "latest" ]; then \
        TAG=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$'); \
    else \
        TAG="$HELIOS_VERSION"; \
    fi && \
    PLATFORM="linux" && \
    case "$TARGETARCH" in \
        amd64) ARCHITECTURE="amd64" ;; \
        arm64) ARCHITECTURE="arm64" ;; \
        arm) ARCHITECTURE="armv7" ;; \
        *) ARCHITECTURE="amd64" ;; \
    esac && \
    TARBALL_URL="https://github.com/$REPO/releases/download/${TAG}/helios_${PLATFORM}_${ARCHITECTURE}.tar.gz" && \
    echo "Downloading helios ${TAG} for ${PLATFORM}_${ARCHITECTURE}" && \
    mkdir -p /helios && \
    curl -L "$TARBALL_URL" | tar -xzC /helios

# Runtime stage - minimal ubuntu with only what's needed to run
FROM ubuntu:24.04

# Install runtime dependencies and create user in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash helios

# Copy binary from downloader stage
COPY --from=downloader /helios/helios /usr/local/bin/helios

USER helios
WORKDIR /home/helios

ENTRYPOINT ["helios"]
CMD ["--help"]
