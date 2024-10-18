#!/bin/bash

# Default values
pass="testT8080"
php_versions=("8.2")
install_supervisor=false

# Show help message
show_help() {
  echo "Usage: install-lamp.sh [options]"
  echo "Options:"
  echo "  -p, --password         Set MySQL root password (default: testT8080)"
  echo "  -v, --php-versions     Install PHP versions (default: 8.2)"
  echo "  --supervisor           Install Supervisor for process management (default: false)"
  echo "  -h, --help             Show this help message"
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

# Update system packages
run_update() {
  echo "+--------------------------------------+"
  echo "|     Updating system packages         |"
  echo "+--------------------------------------+"
  sudo apt-get update -qq
  echo "+--------------------------------------+"
  echo "|     system packages Updated          |"
  echo "+--------------------------------------+"
}

install_apache() {
  echo "+--------------------------------------+"
  echo "|     Installing Apache                |"
  echo "+--------------------------------------+"
  sudo apt-get install -y apache2 > /dev/null 2>&1
  sudo ufw allow in "Apache Full"
  sudo systemctl start apache2
  sudo systemctl enable apache2
  sudo apache2ctl configtest

  sudo tee /var/www/html/index.html > /dev/null <<END
  <!DOCTYPE html>
  <html>
  <head>
  <title>Welcome to Apache!</title>
  </head>
  <body>
  <h1>Apache is installed!</h1>
  <?php
    phpinfo();
  ?>
  </body>
  </html>
END


#check if apache2ctl configtest is successful
if [ $? -ne 0 ]; then
  echo "ERROR: Apache installation failed. Check the Apache configuration."
  exit 1
fi

echo "+--------------------------------------+"
echo "|     Apache Installed Successfully    |"
echo "+--------------------------------------+"

}

# Install MySQL
install_mysql() {
  local pass=$1
  echo "+--------------------------------------+"
  echo "|     Installing MySQL                 |"
  echo "+--------------------------------------+"
  echo "mysql-server mysql-server/root_password password $pass" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $pass" | sudo debconf-set-selections
  sudo apt-get install -y mysql-server > /dev/null 2>&1
  sudo systemctl start mysql
  sudo systemctl enable mysql

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install MySQL."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    MySQL Installed Successfully      |"
  echo "+--------------------------------------+"
}


# Function to detect OS and add the appropriate PHP repository
add_php_repository() {
  echo "+--------------------------------------+"
  echo "|     Adding PHP Repository            |"
  echo "+--------------------------------------+"
  # Get the OS details
  os_name=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  os_version=$(lsb_release -cs)

  if [[ "$os_name" == "ubuntu" ]]; then
    # Add PHP PPA for Ubuntu
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt-get update
  elif [[ "$os_name" == "debian" ]]; then
    # Add PHP repository for Debian
    sudo apt install -y apt-transport-https lsb-release ca-certificates curl
    curl -fsSL https://packages.sury.org/php/README.txt | sudo bash -x
    sudo apt-get update
  else
    echo "Unsupported OS: $os_name"
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    PHP Repository Added Successfully |"
  echo "+--------------------------------------+"
}


# Install PHP and the required extensions
install_php() {
  local php_version=$1
  echo "+--------------------------------------+"
  echo "|     Installing PHP $php_version       |"
  echo "+--------------------------------------+"
  sudo apt-get install -y php$php_version libapache2-mod-php$php_version php$php_version-mysql php$php_version-curl > /dev/null 2>&1
  sudo apt-get install -y php$php_version-mbstring php$php_version-zip php$php_version-gd php$php_version-common php$php_version-xml php$php_version-bcmath php$php_version-fpm > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PHP $php_version."
    exit 1
  fi
  sudo a2enmod php$php_version
  sudo systemctl restart apache2

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable PHP $php_version module."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    PHP $php_version Installed"
  echo "+--------------------------------------+"
}

# Install PhpMyAdmin
install_phpmyadmin() {
  local pass=$1
  echo "+--------------------------------------+"
  echo "|     Installing PhpMyAdmin            |"
  echo "+--------------------------------------+"
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | sudo debconf-set-selections
  sudo apt-get install -y phpmyadmin php-mbstring php-gettext > /dev/null 2>&1
  sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PhpMyAdmin."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    PhpMyAdmin Installed Successfully |"
  echo "+--------------------------------------+"
}


# Install Supervisor
install_supervisor() {
  echo "+--------------------------------------+"
  echo "|     Installing Supervisor            |"
  echo "+--------------------------------------+"
  sudo apt-get install -y supervisor > /dev/null 2>&1
  sudo systemctl start supervisor
  sudo systemctl enable supervisor

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Supervisor."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|  Supervisor Installed Successfully   |"
  echo "+--------------------------------------+"
}

# Remove existing LAMP stack
remove_existing_installation() {
  sudo apt-get purge -y apache2 mysql-server php phpmyadmin > /dev/null 2>&1
  sudo apt-get autoremove -y > /dev/null 2>&1
  sudo apt-get autoclean -y > /dev/null 2>&1
}

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

# start the installation process


# Add PHP repository to ensure the latest PHP versions are available
add_php_repository

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
install_php "$php_versions"
install_phpmyadmin "$pass"

# check if supervisor is to be installed
if [ "$install_supervisor" = true ]; then
  install_supervisor
fi

# Check if all components are installed
if ! is_lamp_installed; then
  echo "+--------------------------------------+"
  echo "|     LAMP Installation Failed         |"
  echo "+--------------------------------------+"
  exit 1
fi

# Display completion message
ip=$(get_server_ip)
echo "+-------------------------------------------+"
echo "|    Finish Auto Install and Setup LAMP"
echo "|"
echo "| Web Site: http://$ip/"
echo "| PhpMyAdmin: http://$ip/phpmyadmin"
echo "| User: root || Pass: $pass"
echo "| Test PHP: http://$ip/info.php"
echo "| Warning: Delete info.php for security"
echo "+-------------------------------------------+"
