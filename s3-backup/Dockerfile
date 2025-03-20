FROM amazonlinux:latest

# Install AWS CLI
RUN yum install -y aws-cli

# Set working directory
WORKDIR /backup

# Copy the backup script
COPY backup.sh /backup/backup.sh
RUN chmod +x /backup/backup.sh

ENTRYPOINT ["/backup/backup.sh"]
