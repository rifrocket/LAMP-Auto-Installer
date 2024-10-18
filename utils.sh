#!/bin/bash

# Show help message
show_help() {
  echo "Usage: install-lamp.sh [options]"
  echo "Options:"
  echo "  -p, --password         Set MySQL root password (default: testT8080)"
  echo "  -v, --php-versions     Install multiple PHP versions (comma-separated)"
  echo "  --supervisor           Install Supervisor for process management"
  echo "  -h, --help             Show this help message"
}

# Update system packages
run_update() {
  echo "Updating system packages..."
  sudo apt-get update -qq
}

# Get server IP
get_server_ip() {
  curl -s https://api.ipify.org
}

# Check if Apache, MySQL, and PHP are installed
is_lamp_installed() {
  apache_status=$(systemctl is-active apache2)
  mysql_status=$(systemctl is-active mysql)
  php_installed=$(php --version 2>/dev/null)

  if [[ "$apache_status" == "active" && "$mysql_status" == "active" && -n "$php_installed" ]]; then
    return 0  # LAMP is installed
  else
    return 1  # LAMP is not installed
  fi
}

# Remove existing LAMP stack
remove_existing_installation() {
  sudo apt-get remove --purge -y apache2 mysql-server php* phpmyadmin
  sudo apt-get autoremove -y
  sudo rm -rf /var/www/html/*
  echo "Existing LAMP stack removed."
}
