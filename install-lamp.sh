#!/bin/bash

# Default values
pass="testT8080"
php_versions=("8.2")
install_supervisor=false
web_server="apache"

# Show help message
show_help() {
  echo "Usage: install-lamp.sh [options]"
  echo "Options:"
  echo "  -w, --web-server       Set web server (apache or nginx) (default: apache)"
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

# Function to install and configure Nginx
install_nginx() {
    echo "+--------------------------------------+"
    echo "|     Installing Nginx                 |"
    echo "+--------------------------------------+"

    # Install Nginx
    sudo apt-get update
    sudo apt-get install -y nginx
    
    # Enable Nginx to start at boot and start it now
    sudo systemctl enable nginx
    sudo systemctl start nginx

    # Install PHP and PHP-FPM
    sudo apt-get install -y php8.2-fpm php8.2-mbstring php8.2-xml php8.2-mysql

    # Configure Nginx to use PHP-FPM
    sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Test Nginx configuration and reload
    sudo nginx -t && sudo systemctl reload nginx

    # Ensure PHP-FPM is running
    sudo systemctl enable php8.2-fpm
    sudo systemctl start php8.2-fpm

    # Create a custom Nginx welcome page
    sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Welcome to Your Nginx Server!</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            background-color: #f4f4f4;
        }
        h1 {
            color: #333;
        }
        p {
            color: #666;
        }
    </style>
</head>
<body>
    <h1>Welcome to Your Nginx Server!</h1>
    <p>The Nginx web server is installed and running on your server.</p>
    <p>PHP version: <?php echo phpversion(); ?></p>
</body>
</html>
EOF

    echo "Custom Nginx welcome page created successfully."
    echo "Nginx installed and configured successfully."
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
  echo "|     Installing PHP $php_version"
  echo "+--------------------------------------+"
  sudo apt-get install -y php$php_version libapache2-mod-php$php_version php$php_version-mysql php$php_version-curl php$php_version-gettext >  /dev/null 2>&1
  sudo apt-get install -y php$php_version-mbstring php$php_version-zip php$php_version-gd php$php_version-common php$php_version-xml php$php_version-bcmath php$php_version-fpm > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PHP $php_version."
    exit 1
  fi

  # Set PHP $php_version as the default PHP version
  sudo update-alternatives --set php /usr/bin/php$php_version
  sudo update-alternatives --set phpize /usr/bin/phpize$php_version
  sudo update-alternatives --set php-config /usr/bin/php-config$php_version


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

  # Pre-configure debconf selections for non-interactive installation
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

  # Install phpMyAdmin and required PHP extensions
  sudo apt-get install -y phpmyadmin

  # Check if phpMyAdmin was successfully installed
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PhpMyAdmin."
    exit 1
  fi

  # Enable required PHP extensions for phpMyAdmin
  sudo phpenmod mbstring
  sudo phpenmod gettext

  # Check if symbolic link exists and remove it if necessary
  if [ -L /var/www/html/phpmyadmin ] || [ -d /var/www/html/phpmyadmin ]; then
    echo "Existing phpMyAdmin directory or symlink found. Removing it..."
    sudo rm -rf /var/www/html/phpmyadmin
  fi

  # Create a new symbolic link to phpMyAdmin
  sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create symbolic link for PhpMyAdmin."
    exit 1
  fi

  # Restart Apache to apply changes
  sudo systemctl restart apache2

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
  echo "+--------------------------------------+"
  echo "|  Removing Existing LAMP Installation |"
  echo "+--------------------------------------+"

  # Stop Apache and MySQL services first to avoid issues during removal
  sudo systemctl stop apache2 mysql

  # Purge Apache, MySQL, PHP, and phpMyAdmin
  sudo apt-get purge -y apache2 apache2-utils apache2-bin apache2.2-common
  sudo apt-get purge -y mysql-server mysql-client mysql-common
  sudo apt-get purge -y php* phpmyadmin

  # Autoremove unnecessary dependencies and clean up apt cache
  sudo apt-get autoremove -y
  sudo apt-get autoclean -y

  # Remove leftover configuration files and data directories
  sudo rm -rf /etc/apache2
  sudo rm -rf /etc/mysql
  sudo rm -rf /etc/php
  sudo rm -rf /etc/phpmyadmin

  # Optionally remove MySQL databases (CAUTION: This will delete all your MySQL data)
  sudo rm -rf /var/lib/mysql
  sudo rm -rf /var/www/html
  
  # Clean up other residual files
  sudo rm -rf /var/log/apache2
  sudo rm -rf /var/log/mysql
  sudo rm -rf /var/cache/apache2
  sudo rm -rf /usr/share/phpmyadmin

  echo "+--------------------------------------+"
  echo "|   Existing Installation Removed      |"
  echo "+--------------------------------------+"
}


# Function to fix deprecated http_build_query usage in PhpMyAdmin
fix_phpmyadmin_deprecation() {
    echo "+--------------------------------------+"
    echo "|     Fixing PhpMyAdmin Deprecation    |"
    echo "+--------------------------------------+"

    # Path to the PhpMyAdmin Url.php file
    PHPMYADMIN_URL_PHP="/usr/share/phpmyadmin/libraries/classes/Url.php"

    # Check if the file exists
    if [ -f "$PHPMYADMIN_URL_PHP" ]; then
        # Use sed to find and replace the deprecated code
        sudo sed -i 's/http_build_query(\$queryParams, null, /http_build_query(\$queryParams, "", /' "$PHPMYADMIN_URL_PHP"

        if [ $? -eq 0 ]; then
            echo "PhpMyAdmin deprecation issue fixed successfully."
        else
            echo "ERROR: Failed to fix PhpMyAdmin deprecation issue."
            exit 1
        fi
    else
        echo "ERROR: PhpMyAdmin Url.php file not found."
        exit 1
    fi
}


# Parse arguments
while [ "$1" != "" ]; do
  case "$1" in
    -w | --web-server ) web_server=$2; shift 2;;
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

# Install Server
if [ "$web_server" == "apache" ]; then
  install_apache
elif [ "$web_server" == "nginx" ]; then
  install_nginx
else
  echo "Unsupported web server: $web_server"
  exit 1
fi

install_mysql "$pass"
install_php "$php_versions"
install_phpmyadmin "$pass"
fix_phpmyadmin_deprecation

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
