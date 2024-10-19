
# LAMP Auto-Installer

## Overview

This is a fully automated script to install and set up a **LAMP (Linux, Apache, MySQL, PHP)** stack on any DigitalOcean droplet or Ubuntu server. It also includes the installation of **phpMyAdmin** for database management and configuration of **Apache** and **PHP**. This script is designed to make the process seamless and reduce manual intervention.

## Features

- **Apache or Nginx Web Server**: You can choose to install Apache or Nginx as the web server.
- **MySQL Database**: Handles your database with secure installation.
- **PHP Versions**: You can specify which PHP versions to install (default: 8.2).
- **phpMyAdmin**: Database management tool accessible via browser.
- **Optional Supervisor**: Install Supervisor for process management if required.
- **Force Reinstallation**: Use the `--force-reinstall` flag to automatically reinstall LAMP if it is already installed.
- **Automated Removal**: Use the `--remove` flag to automatically remove the LAMP stack.
- **Automated Configuration**: Automatically configures Apache/Nginx, PHP, and MySQL with default values or user-provided settings.

## Requirements

- A fresh Ubuntu server (preferably DigitalOcean droplet or similar VPS).
- Root access or `sudo` privileges.

## Usage

### Quick Start

Run the following one-liner on your server to automatically download and execute the script:

```bash
wget --no-check-certificate -O /tmp/install-lamp.sh https://raw.githubusercontent.com/rifrocket/LAMP-Auto-Installer/main/install-lamp.sh; sudo bash /tmp/install-lamp.sh --composer
```

### Custom Password and PHP Versions

You can set a custom MySQL root password and specify PHP version by passing the `-p` or `--password` and `-v` or `--php-version` flags:

```bash
sudo bash install-lamp.sh -p MyCustomPassword123 -v 8.2
```

### Optional Supervisor Installation

To install Supervisor along with the LAMP stack, pass the `--supervisor` flag:

```bash
sudo bash install-lamp.sh --supervisor
```

### Install Nginx Instead of Apache

You can install Nginx instead of Apache by passing the `--nginx` flag:

```bash
sudo bash install-lamp.sh --nginx
```

### Reinstall LAMP Automatically

If LAMP is already installed and you want to reinstall it automatically without any prompts, use the `--force-reinstall` flag:

```bash
sudo bash install-lamp.sh --force-reinstall
```

### Remove LAMP Stack

To remove the LAMP stack automatically, pass the `--remove` flag:

```bash
sudo bash install-lamp.sh --remove
```

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
2. **Install Apache/Nginx**: Installs and configures Apache or Nginx web server based on the flag provided.
3. **Install MySQL**: Installs MySQL and secures it with automated responses.
4. **Install PHP Versions**: Installs PHP versions (you can specify version).
5. **Configure PHP**: Updates PHP settings (e.g., timezone, max upload size).
6. **Install PhpMyAdmin**: Sets up phpMyAdmin for database management.
7. **Restart Services**: Automatically restarts Apache/Nginx and PHP services to apply changes.
8. **Display Installation Summary**: Shows access details for the web server, phpMyAdmin, and PHP.
9. **Optional Supervisor Installation**: Installs Supervisor for process management (if specified).
10. **Reinstall or Remove LAMP**: Automatically reinstalls or removes LAMP stack if flags are passed.

## Customization

The script can be easily modified to suit your needs. Some customization options include:

- Changing the default **timezone** in the PHP configuration.
- Updating the **max_execution_time** and **upload_max_filesize** in PHP.
- Modifying the **document root** of the Apache/Nginx server.

## Troubleshooting

- **Unable to access phpMyAdmin**: Make sure Apache or Nginx is running and there are no firewall rules blocking HTTP traffic.
- **MySQL login issues**: If you forget the MySQL root password, rerun the script with the `-p` flag to set a new password.
- **Apache/Nginx service not starting**: Check the logs using `sudo journalctl -xe` for web server-related errors.

## Contributions

If you’d like to contribute to this project:

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/new-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/new-feature`).
5. Create a new Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

PAF*VK-Lq&xc9bG