#!/bin/bash

# Default values
mysql_pass="testT8080"
php_versions=("8.2")
install_lamp=false
install_lemp=false
install_composer=false
install_supervisor=false
remove_web_server=false

# Show help message
show_help() {
  cat << EOF
Usage: install-lamp.sh [options]

Options:
  --lamp                    Install LAMP stack (Apache, MySQL, PHP)
  --lemp                    Install LEMP stack (Nginx, MySQL, PHP)
  
Customization Options:
  -p, --mysql-password          Set MySQL root password (default: testT8080)
  -v, --php-version             Specify PHP version(s) to install (default: 8.2, multiple versions comma-separated)
  -s, --supervisor              Install Supervisor (default: false, use flag to enable)
  -c, --composer                Install Composer (default: false, use flag to enable)
  -r, --remove                  Remove existing LAMP or LEMP stack (default: false, use flag to enable)
  -h, --help                    Show this help message

Examples:
  ./install-lamp.sh --lamp
  ./install-lamp.sh --lemp --php-version=8.2 --mysql-password=mysecurepassword
  
EOF
}

# Parse arguments
while [ "$1" != "" ]; do
  case "$1" in
    --lamp ) install_lamp=true; shift ;;
    --lemp ) install_lemp=true; shift ;;
    -p | --mysql-password ) mysql_pass="$2"; shift 2 ;;
    -v | --php-version ) php_versions="$2"; shift 2 ;;
    -c | --composer ) install_composer=true; shift ;;
    -s | --supervisor ) install_supervisor=true; shift ;;
    -r | --remove ) remove_web_server=true; shift ;;
    -h | --help ) show_help; exit ;;
    * ) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# Get server IP
get_server_ip() {
  curl -s https://api.ipify.org || echo "localhost"
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

is_lemp_installed() {
  nginx_status=$(systemctl is-active nginx)
  mysql_status=$(systemctl is-active mysql)
  php_installed=$(php --version 2>/dev/null)

  if [[ "$nginx_status" == "active" && "$mysql_status" == "active" && -n "$php_installed" ]]; then
    return 0  # LEMP is installed
  else
    return 1  # LEMP is not installed
  fi
}

# Update system packages
update_system() {
  echo "+--------------------------------------+"
  echo "|     Updating system packages         |"
  echo "+--------------------------------------+"
  sudo apt-get update -qq
  echo "+--------------------------------------+"
  echo "|     System packages updated          |"
  echo "+--------------------------------------+"
}

# Add PHP repository based on OS
add_php_repository() {
  echo "+--------------------------------------+"
  echo "|     Adding PHP Repository            |"
  echo "+--------------------------------------+"

  os_name=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  os_version=$(lsb_release -cs)

  if [[ "$os_name" == "ubuntu" ]]; then
    if ! grep -q "^deb .*$os_version.*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
      sudo apt install -y software-properties-common
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install software-properties-common."
        exit 1
      fi

      sudo add-apt-repository -y ppa:ondrej/php
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to add PHP repository."
        exit 1
      fi

      sudo apt-get update
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to update package list."
        exit 1
      fi
    else
      echo "PHP repository already added. Skipping..."
    fi
  elif [[ "$os_name" == "debian" ]]; then
    if ! grep -q "^deb .*sury.org/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
      sudo apt install -y apt-transport-https lsb-release ca-certificates curl
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install required packages."
        exit 1
      fi

      curl -fsSL https://packages.sury.org/php/README.txt | sudo bash -x
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to add PHP repository."
        exit 1
      fi

      sudo apt-get update
      if [ $? -ne 0 ]; then
        echo "ERROR: Failed to update package list."
        exit 1
      fi
    else
      echo "PHP repository already added. Skipping..."
    fi
  else
    echo "Unsupported OS: $os_name"
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|   PHP Repository Added Successfully  |"
  echo "+--------------------------------------+"
}

# Install PHP and required extensions
install_php() {
  local php_version=$1
  echo "+--------------------------------------+"
  echo "|     Installing PHP $php_version      |"
  echo "+--------------------------------------+"

  # Add the PHP repository before installation
  add_php_repository
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to add PHP repository."
    exit 1
  fi
  
  # Install PHP and required extensions
  sudo apt-get install -y \
    unzip \
    openssl \
    php$php_version \
    libapache2-mod-php$php_version \
    php$php_version-mysql \
    php$php_version-curl \
    php$php_version-cli \
    php$php_version-gettext \
    php$php_version-mbstring \
    php$php_version-zip \
    php$php_version-gd \
    php$php_version-common \
    php$php_version-xml \
    php$php_version-bcmath \
    php$php_version-tokenizer \
    php$php_version-json \
    php$php_version-fpm > /dev/null 2>&1

  # Check if installation was successful
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PHP $php_version."
    exit 1
  fi

  # Set PHP version as default
  sudo update-alternatives --set php /usr/bin/php$php_version \
    && sudo update-alternatives --set phpize /usr/bin/phpize$php_version \
    && sudo update-alternatives --set php-config /usr/bin/php-config$php_version
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set PHP $php_version as default."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    PHP $php_version Installed       |"
  echo "+--------------------------------------+"
}

# Install Apache
install_apache() {
  echo "+--------------------------------------+"
  echo "|     Installing Apache                |"
  echo "+--------------------------------------+"

  sudo apt-get install -y apache2 > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Apache."
    exit 1
  fi

  sudo ufw allow in "Apache Full"

  sudo systemctl start apache2 && sudo systemctl enable apache2
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start or enable Apache."
    exit 1
  fi

  sudo apache2ctl configtest
  if [ $? -ne 0 ]; then
    echo "ERROR: Apache configuration test failed."
    exit 1
  fi

  # Enable PHP module and restart the web server
  sudo a2enmod php$php_version
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable PHP module."
    exit 1
  fi

  sudo systemctl restart apache2
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to restart Apache."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|     Apache Installed Successfully    |"
  echo "+--------------------------------------+"
}

# Install Nginx
install_nginx() {
  echo "+--------------------------------------+"
  echo "|     Installing Nginx                 |"
  echo "+--------------------------------------+"

  sudo apt-get install -y nginx > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Nginx."
    exit 1
  fi

  sudo ufw allow "Nginx Full"

  sudo systemctl enable nginx && sudo systemctl start nginx
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable or start Nginx."
    exit 1
  fi

  sudo systemctl restart nginx
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to restart Nginx."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|  Nginx installed and configured      |"
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
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install MySQL."
    exit 1
  fi

  sudo systemctl start mysql && sudo systemctl enable mysql
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start or enable MySQL."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|    MySQL Installed Successfully      |"
  echo "+--------------------------------------+"
}



# Install phpMyAdmin
install_phpmyadmin() {
  local pass=$1
  echo "+--------------------------------------+"
  echo "|     Installing PhpMyAdmin            |"
  echo "+--------------------------------------+"

  # Pre-configure debconf selections for non-interactive installation
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

  # Install phpMyAdmin
  sudo apt-get install -y phpmyadmin
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PhpMyAdmin."
    exit 1
  fi

  # Enable required PHP extensions for phpMyAdmin
  sudo phpenmod mbstring gettext
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable required PHP extensions."
    exit 1
  fi

  # Remove existing symlink if exists
  if [ -e /var/www/html/phpmyadmin ]; then
    echo "Existing phpMyAdmin directory found. Removing it..."
    sudo rm -rf /var/www/html/phpmyadmin
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to remove existing phpMyAdmin directory."
      exit 1
    fi
  fi

  # Create a new symbolic link to phpMyAdmin
  sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create symbolic link for phpMyAdmin."
    exit 1
  fi

  # Restart Apache to apply changes
  sudo systemctl restart apache2
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to restart Apache."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|  PhpMyAdmin Installed Successfully   |"
  echo "+--------------------------------------+"
}

# Install Supervisor
install_supervisor() {
  echo "+--------------------------------------+"
  echo "|     Installing Supervisor            |"
  echo "+--------------------------------------+"

  sudo apt-get install -y supervisor > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Supervisor."
    exit 1
  fi

  sudo systemctl start supervisor && sudo systemctl enable supervisor
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start or enable Supervisor."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|  Supervisor Installed Successfully   |"
  echo "+--------------------------------------+"
}

# install Composer
install_composer() {
  echo "+--------------------------------------+"
  echo "|     Installing Composer              |"
  echo "+--------------------------------------+"

  sudo apt install php-cli unzip -y > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install required packages."
    exit 1
  fi

  cd ~
  curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download Composer installer."
    exit 1
  fi

  HASH=$(curl -sS https://composer.github.io/installer.sig)
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to retrieve Composer installer hash."
    exit 1
  fi

  echo $HASH
  php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('/tmp/composer-setup.php'); } echo PHP_EOL;"
  if [ $? -ne 0 ]; then
    echo "ERROR: Composer installer verification failed."
    exit 1
  fi

  sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Composer."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|  Composer Installed Successfully     |"
  echo "+--------------------------------------+"
}

# Remove existing LAMP stack
remove_existing_installation() {
  echo "+--------------------------------------------+"
  echo "|  Removing Existing Web Server Installation |"
  echo "+--------------------------------------------+"

  if command -v apache2 > /dev/null 2>&1; then
    sudo apt-get purge -y apache2
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to purge Apache."
      exit 1
    fi
    sudo rm -rf /etc/apache2
  elif command -v nginx > /dev/null 2>&1; then
    sudo apt-get purge -y nginx
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to purge Nginx."
      exit 1
    fi
    sudo rm -rf /etc/nginx
  fi 

  # Purge installed components
  sudo apt-get purge -y mysql-server php* phpmyadmin
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to purge MySQL, PHP, or phpMyAdmin."
    exit 1
  fi

  sudo apt-get autoremove -y
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to autoremove packages."
    exit 1
  fi

  sudo apt-get autoclean -y
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to autoclean packages."
    exit 1
  fi

  sudo rm -rf /etc/mysql /etc/php /usr/share/phpmyadmin /var/www/html/index.html
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to remove directories."
    exit 1
  fi

  echo "+--------------------------------------+"
  echo "|   Existing Installation Removed      |"
  echo "+--------------------------------------+"
}

# Run the installation steps
update_system

if $remove_web_server; then
  remove_existing_installation
fi

if $install_lamp; then
  install_php $php_version
  install_apache
  install_mysql $mysql_pass
  install_phpmyadmin $mysql_pass
fi

if $install_lemp; then  
  install_php $php_version
  install_nginx
  install_mysql $mysql_pass
  install_phpmyadmin $mysql_pass
fi

if $install_composer; then
  install_composer
fi

if $install_supervisor; then
  install_supervisor
fi




# Display completion message
ip=$(get_server_ip)
echo "+-------------------------------------------+"
echo "|    Finish Auto Install and Setup LAMP    |"
echo "| Web Site: http://$ip/                    |"
echo "| PhpMyAdmin: http://$ip/phpmyadmin        |"
echo "| User: root || Pass: $pass                |"
echo "+-------------------------------------------+"
