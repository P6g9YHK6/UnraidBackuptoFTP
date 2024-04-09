# UnraidBackupToFTP Automated Unraid Backup Script

This script automates the process of creating backups from the Unraid USB boot drive and sending them to an FTP server. It also includes functionalities to maintain a desired number of backups and provides status updates via a Gotify push.

## Configuration

Before running the script, make sure to configure the following variables:

- `FTP_SERVER`: FTP server address.
- `FTP_USER`: FTP username.
- `FTP_PASSWORD`: FTP password.
- `FTP_DIR`: FTP directory to upload backups.
- `STATUS_API`: URL for the Gotify API for status updates.

It's recommended to use this script with the Community Applications User Scripts plugin. You can find more information about the plugin [here](https://forums.unraid.net/topic/48286-plugin-ca-user-scripts/).
