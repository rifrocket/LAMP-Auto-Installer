# LAMP Auto-Installer

## Overview

This is a fully automated script to install and set up a **LAMP (Linux, Apache, MySQL, PHP)** stack on any DigitalOcean droplet or Ubuntu server. It also includes the installation of **phpMyAdmin** for database management and configuration of **Apache** and **PHP 8.2**. This script is designed to make the process seamless and reduce manual intervention.

## Features

- **Apache Web Server**: Serves your web applications.
- **MySQL Database**: Handles your database with secure installation.
- **PHP 8.2**: Latest PHP version with necessary extensions.
- **phpMyAdmin**: Database management tool accessible via browser.
- **Automated Configuration**: Automatically configures Apache, PHP, and MySQL with default values or user-provided settings.
- **Default Web Pages**: Simple web page and PHP info page to confirm the installation.

## Requirements

- A fresh Ubuntu server (preferably DigitalOcean droplet or similar VPS).
- Root access or `sudo` privileges.

## Usage

### Quick Start

Run the following one-liner on your server to automatically download and execute the script:

```bash
wget --no-check-certificate -O /tmp/install-lamp.sh https://raw.githubusercontent.com/rifrocket/LAMP-Auto-Installer/main/install-lamp.sh; sudo bash /tmp/install-lamp.sh
```

### Custom Password

You can set a custom MySQL root password by passing the `-p` or `--password` flag:

```bash
sudo bash install-lamp.sh -p MyCustomPassword123
```

### Default Installation

If no password is provided, the script will use the default MySQL password `testT8080`.

### Help

For help and available options, run:

```bash
sudo bash install-lamp.sh -h
```

### Access

After the installation is complete, you can access your server’s LAMP stack via the following URLs:

- **Web Server**: `http://<your-server-ip>/`
- **phpMyAdmin**: `http://<your-server-ip>/phpmyadmin`
  - **MySQL Root User**: `root`
  - **Password**: Set by you or the default (`testT8080`)

- **PHP Info**: `http://<your-server-ip>/info.php`
  - **Note**: It is highly recommended to delete the `info.php` file after verifying PHP is working to avoid exposing sensitive server information.

## What Does the Script Do?

1. **System Update**: The script updates your system’s package index.
2. **Install Apache**: Installs and configures Apache web server.
3. **Install MySQL**: Installs MySQL and secures it with automated responses.
4. **Install PHP 8.2**: Installs PHP and its necessary extensions.
5. **Configure PHP**: Updates PHP settings (e.g., timezone, max upload size).
6. **Install phpMyAdmin**: Sets up phpMyAdmin for database management.
7. **Restart Services**: Automatically restarts Apache and PHP services to apply changes.
8. **Display Installation Summary**: Shows access details for the web server, phpMyAdmin, and PHP.

## Customization

The script can be easily modified to suit your needs. Some customization options include:

- Changing the default **timezone** in the PHP configuration.
- Updating the **max_execution_time** and **upload_max_filesize** in PHP.
- Modifying the **document root** of the Apache server.

Feel free to fork this repository and modify the script as needed!

## Troubleshooting

- **Unable to access phpMyAdmin**: Make sure Apache is running and there are no firewall rules blocking HTTP traffic.
- **MySQL login issues**: If you forget the MySQL root password, rerun the script with the `-p` flag to set a new password.
- **Apache service not starting**: Check the logs using `sudo journalctl -xe` for Apache-related errors.

## Logs

All the installation processes are silently handled, but you can remove the `> /dev/null 2>&1` from the script if you'd like to see the output of each command.

## Directory Structure

```
LAMP-Auto-Installer/
├── install-lamp.sh     # The installation script
├── README.md           # This documentation file
```

## Contributions

If you’d like to contribute to this project:

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.