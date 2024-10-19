
# LAMP/LEMP Automated Installer

This script automates the installation of a LAMP (Linux, Apache, MySQL, PHP) or LEMP (Linux, Nginx, MySQL, PHP) stack on Ubuntu-based systems.

## Features

- Install LAMP or LEMP with one command.
- Specify PHP version (default is 8.2).
- Includes MySQL installation with password setup.
- Supports installing Supervisor and Composer.

## Requirements

- Ubuntu-based distribution (version < 22)
- `curl`, `debconf`, and `add-apt-repository` should be installed.

## Usage

### Basic Usage

To install the LAMP stack (Apache, MySQL, PHP), run:
```
./install-lamp.sh --lamp
```

To install the LEMP stack (Nginx, MySQL, PHP), run:
```
./install-lamp.sh --lemp
```

### Customization Options

- Set MySQL root password:
```
./install-lamp.sh --lamp --mysql-password=yourpassword
```

- Install specific PHP version (e.g., PHP 8.1):
```
./install-lamp.sh --lamp --php-version=8.1
```

### Additional Options

- `--force-reinstall`: Force reinstall of the LAMP/LEMP stack.
- `--supervisor`: Install Supervisor.
- `--composer`: Install Composer.

## Logs

All installation logs are saved to `/var/log/lamp_install.log`.
