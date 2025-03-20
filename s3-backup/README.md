# S3 Backup Script (Glacier Deep Archive)

This script automatically syncs a local directory to Amazon S3 using **Glacier Deep Archive** for cost-effective storage. It logs changes and sends email notifications via AWS SES.

## Features

- One-way sync (local → S3)
- Uses **Glacier Deep Archive** for low-cost storage
- Logs changes in `backup_log.txt`
- Sends email notifications via AWS SES
- Dockerized for easy deployment
- Supports cron scheduling (weekly/monthly)
- Uses Docker environment variables for flexibility

## Setup Instructions

1. Build the Docker image:

   ```sh
   docker build -t s3-backup .
   ```

2. Run the script:
   ```sh
   docker run --rm
    -e AWS_ACCESS_KEY_ID=your-access-key
    -e AWS_SECRET_ACCESS_KEY=your-secret-key
    -e AWS_DEFAULT_REGION=your-region
    -e S3_BUCKET=s3://your-bucket-name
    -e LOCAL_DIR=/data
    -e STORAGE_CLASS=DEEP_ARCHIVE
    -e EMAIL_FROM=ses-verified-email@example.com
    -e EMAIL_TO=your-email@example.com
    -v /path/to/data:/data
    -v /path/to/logs:/backup
    s3-backup
   ```

## Automate with Cron

**Weekly Backup (Sunday 2 AM)**:

```sh
0 2 * * 0 docker run --rm <same command as above>
```

**Monthly Backup (1st of the Month, 3 AM)**:

```sh
0 3 1 * * docker run --rm <same command as above>
```

## Restore from Glacier Deep Archive

```sh
aws s3 restore-object --bucket your-bucket-name --key path/to/file --restore-request '{"Days":7,"GlacierJobParameters":{"Tier":"Standard"}}'
```

You're all set! 🚀
