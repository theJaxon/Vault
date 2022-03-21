FROM bitnami/minideb:bullseye

ENV VAULT_VERSION=1.9.4 \
    BIN_DIR=/usr/local/bin

RUN install_packages \
    ca-certificates \
    curl \
    wget \
    unzip \
    gnupg && \

# Install Vault CLI
wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip --directory-prefix /tmp && \
unzip /tmp/vault_${VAULT_VERSION}_linux_amd64.zip -d ${BIN_DIR} && \

# Install minio CLI
wget https://dl.min.io/client/mc/release/linux-amd64/mc --directory-prefix ${BIN_DIR} && \
chmod +x ${BIN_DIR}/mc && \

# Remove aliases from mc config file at /root/.mc/config.json
mc alias remove play && \
mc alias remove gcs && \ 
mc alias remove s3 && \ 
mc alias remove local && \

# Remove unneeded files 
rm -rf /tmp/vault_${VAULT_VERSION}_linux_amd64.zip