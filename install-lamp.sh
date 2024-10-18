#!/bin/bash

# Base URL to download the scripts
BASE_URL="https://raw.githubusercontent.com/rifrocket/LAMP-Auto-Installer/main"

# Download the necessary files if they don't already exist
download_files() {
  files=("utils.sh" "apache.sh" "mysql.sh" "php.sh" "phpmyadmin.sh")

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      echo "Downloading $file..."
      wget -q "$BASE_URL/$file" -O "$file"
      if [ $? -ne 0 ]; then
        echo "Failed to download $file. Exiting."
        exit 1
      fi
      chmod +x "$file"
    fi
  done
}

# Load the downloaded scripts
load_scripts() {
  source ./utils.sh
  source ./apache.sh
  source ./mysql.sh
  source ./php.sh
  source ./phpmyadmin.sh
}

# Check for PHP versions and install the latest stable version if php8.2 is not available
install_latest_php() {
  local available_php_version=$(apt-cache search php | grep -oP 'php[0-9]+\.[0-9]+$' | sort -V | tail -n 1)

  if [ -n "$available_php_version" ]; then
    echo "Installing PHP version $available_php_version..."
    sudo apt-get install -y "$available_php_version" libapache2-mod-"$available_php_version" php"$available_php_version"-mysql php"$available_php_version"-curl > /dev/null 2>&1
    sudo a2enmod "$available_php_version"
    sudo systemctl restart apache2
  else
    echo "ERROR: No PHP version found in repositories!"
    exit 1
  fi
}

# Ensure proper permissions for PhpMyAdmin
fix_phpmyadmin_permissions() {
  sudo chown -R www-data:www-data /usr/share/phpmyadmin
  sudo chmod -R 755 /usr/share/phpmyadmin
  echo "PhpMyAdmin permissions fixed."
}

# Default values
pass="testT8080"
php_versions=("8.2")
install_supervisor=false

# Parse arguments
while [ "$1" != "" ]; do
  case "$1" in
    -p | --password ) pass=$2; shift 2;;
    -v | --php-versions ) IFS=',' read -r -a php_versions <<< "$2"; shift 2;;
    --supervisor ) install_supervisor=true; shift;;
    -h | --help ) show_help; exit;;
    * ) echo "Unknown option: $1"; show_help; exit 1;;
  esac
done

# Download necessary files
download_files

# Load the scripts
load_scripts

# Check if LAMP stack is already installed
if is_lamp_installed; then
  echo "LAMP stack seems to be already installed. Do you want to reinstall? (y/n)"
  read -r choice
  if [ "$choice" != "y" ]; then
    echo "Aborting installation."
    exit 1
  else
    echo "Removing existing LAMP stack..."
    remove_existing_installation
  fi
fi

# Run the installation steps
run_update
install_apache
install_mysql "$pass"

# PHP Installation - Handle case where PHP 8.2 is not available
if apt-cache search php8.2 | grep php8.2 > /dev/null; then
  install_php "8.2"
else
  echo "PHP 8.2 not found, installing the latest available PHP version..."
  install_latest_php
fi

# Fix PhpMyAdmin access issues
fix_phpmyadmin_permissions

# Optional Supervisor installation
if [ "$install_supervisor" = true ]; then
  source ./supervisor.sh
  install_supervisor_service
fi

install_phpmyadmin "$pass"

# Display completion message
ip=$(get_server_ip)
echo "+-------------------------------------------+"
echo "|    Finish Auto Install and Setup LAMP      |"
echo "|                                           |"
echo "| Web Site: http://$ip/"
echo "| PhpMyAdmin: http://$ip/phpmyadmin"
echo "| User: root || Pass: $pass"
echo "| Test PHP: http://$ip/info.php"
echo "| Warning: Delete info.php for security      |"
echo "+-------------------------------------------+"
