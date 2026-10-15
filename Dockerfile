# Use Golang 1.22 on Debian Bookworm (provides Go 1.22, git, and C build tools for CGO)
FROM golang:1.22-bookworm

ARG HUGO_VERSION=0.168.0

# Install Node.js 20 & build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Hugo Extended matching Netlify configuration (v0.133.1)
RUN dpkg_arch="$(dpkg --print-architecture)" \
    && case "${dpkg_arch}" in \
    amd64) HUGO_ARCH="linux-amd64" ;; \
    arm64) HUGO_ARCH="linux-arm64" ;; \
    *) echo "Unsupported architecture: ${dpkg_arch}" && exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz" -o hugo.tar.gz \
    && tar -xzf hugo.tar.gz -C /usr/local/bin hugo \
    && rm hugo.tar.gz \
    && hugo version

WORKDIR /src

EXPOSE 1313

CMD ["hugo", "server", "--bind", "0.0.0.0", "--baseURL", "http://localhost:1313", "--buildDrafts", "--buildFuture", "--watch", "--poll", "700ms"]
