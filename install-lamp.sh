#!/bin/bash

# Default values
pass="testT8080"
php_versions=("8.2")
install_supervisor=false
web_server="apache"
install_mysql=false
install_php=false
install_phpmyadmin=false
install_phpmyadmin_pass="testT8080"
force_reinstall=false
remove_lamp=false
install_lamp=false
install_lemp=false

# Show help message
show_help() {
  printf "Usage: install-lamp.sh [options]\n"
  printf "\nOptions:\n\n"
  printf "  --lamp                    Install LAMP stack (default: false, use flag to enable)\n"
  printf "  --lemp                    Install LEMP stack (default: false, use flag to enable)\n"
  printf "\nCustomization Options:\n\n"
  printf "  --web-server              Set web server (apache or nginx) (default: apache)\n"
  printf "  --mysql                   Install MySQL (default: false, use flag to enable)\n"
  printf "  --mysql-password          Set MySQL root password (default: testT8080)\n"
  printf "  --php                     Install PHP (default: false, default version: 8.2, specify version with --php=<version>)\n"
  printf "  --phpmyadmin              Install phpMyAdmin (default: false, use flag to enable)\n"
  printf "  --phpmyadmin-password     Set phpMyAdmin password (default: testT8080)\n"
  printf "  --supervisor              Install Supervisor (default: false, use flag to enable)\n"
  printf "  --remove                  Remove existing LAMP or LEMP stack (default: false, use flag to enable)\n"
  printf "  -h, --help                Show this help message\n"
  printf "\nExamples:\n\n"
  printf "  ./install-lamp.sh --lamp\n"
  printf "  ./install-lamp.sh --lemp\n"
  printf "  ./install-lamp.sh --lamp --mysql-password=mysecurepassword\n"
  printf "  ./install-lamp.sh --web-server=nginx --php=8.2 --mysql --mysql-password=mysqlpass --phpmyadmin --phpmyadmin-password=myadminpass\n\n"
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
  echo "|     System packages updated          |"
  echo "+--------------------------------------+"
}

# Install Apache
install_apache() {
  echo "+--------------------------------------+"
  echo "|     Installing Apache                |"
  echo "+--------------------------------------+"
  sudo apt-get install -y apache2 > /dev/null 2>&1
  sudo ufw allow in "Apache Full"
  sudo systemctl start apache2 || { echo "Failed to start Apache."; exit 1; }
  sudo systemctl enable apache2
  sudo apache2ctl configtest

  if [ $? -ne 0 ]; then
    echo "ERROR: Apache installation failed. Check the Apache configuration."
    exit 1
  fi

  sudo tee /var/www/html/index.html > /dev/null <<END
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Apache!</title>
</head>
<body>
<h1>Apache is installed!</h1>
<?php phpinfo(); ?>
</body>
</html>
END

  echo "+--------------------------------------+"
  echo "|     Apache Installed Successfully    |"
  echo "+--------------------------------------+"
}

# Install Nginx
install_nginx() {
  echo "+--------------------------------------+"
  echo "|     Installing Nginx                |"
  echo "+--------------------------------------+"

  sudo apt-get install -y nginx

  sudo systemctl enable nginx
  sudo systemctl start nginx || { echo "Failed to start Nginx."; exit 1; }

  # Install PHP-FPM
  for version in "${php_versions[@]}"; do
    sudo apt-get install -y php${version}-fpm
  done

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
        fastcgi_pass unix:/var/run/php/php${php_versions[0]}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

  sudo nginx -t && sudo systemctl reload nginx
  echo "Custom Nginx welcome page created successfully."
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

# Add PHP repository based on OS
add_php_repository() {
  echo "+--------------------------------------+"
  echo "|     Adding PHP Repository            |"
  echo "+--------------------------------------+"

  os_name=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  os_version=$(lsb_release -cs)

  if [[ "$os_name" == "ubuntu" ]]; then
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y
  elif [[ "$os_name" == "debian" ]]; then
    sudo apt install -y apt-transport-https lsb-release ca-certificates curl
    curl -fsSL https://packages.sury.org/php/README.txt | sudo bash -x
  else
    echo "Unsupported OS: $os_name"
    exit 1
  fi

  sudo apt-get update
  echo "+--------------------------------------+"
  echo "|    PHP Repository Added Successfully |"
  echo "+--------------------------------------+"
}

# Install PHP and required extensions
install_php() {
  local php_version=$1
  echo "+--------------------------------------+"
  echo "|     Installing PHP $php_version      |"
  echo "+--------------------------------------+"
  add_php_repository
  sudo apt-get install -y php$php_version libapache2-mod-php$php_version php$php_version-mysql php$php_version-curl php$php_version-gettext > /dev/null 2>&1
  sudo apt-get install -y php$php_version-mbstring php$php_version-zip php$php_version-gd php$php_version-common php$php_version-xml php$php_version-bcmath php$php_version-fpm > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install PHP $php_version."
    exit 1
  fi

  # Set PHP version as default
  sudo update-alternatives --set php /usr/bin/php$php_version
  sudo update-alternatives --set phpize /usr/bin/phpize$php_version
  sudo update-alternatives --set php-config /usr/bin/php-config$php_version

if command -v apache2 > /dev/null; then
  sudo a2enmod php$php_version
  sudo systemctl restart apache2
elif command -v nginx > /dev/null; then
  sudo systemctl restart php$php_version-fpm
fi

  echo "+--------------------------------------+"
  echo "|    PHP $php_version Installed       |"
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
  sudo phpenmod mbstring
  sudo phpenmod gettext

  # Remove existing symlink if exists
  if [ -L /var/www/html/phpmyadmin ] || [ -d /var/www/html/phpmyadmin ]; then
    echo "Existing phpMyAdmin directory found. Removing it..."
    sudo rm -rf /var/www/html/phpmyadmin
  fi

  # Create a new symbolic link to phpMyAdmin
  sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

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

  # Stop services to avoid issues during removal
  sudo systemctl stop apache2 mysql

  # Purge installed components
  sudo apt-get purge -y apache2 mysql-server php* phpmyadmin
  sudo apt-get autoremove -y
  sudo apt-get autoclean -y

  # Remove configuration files
  sudo rm -rf /etc/apache2 /etc/mysql /etc/php /usr/share/phpmyadmin

  echo "+--------------------------------------+"
  echo "|   Existing Installation Removed      |"
  echo "+--------------------------------------+"
}

# Parse arguments
while [ "$1" != "" ]; do
  case "$1" in
    --web-server ) web_server=$2; shift 2;;
    --mysql ) install_mysql=true; shift;;
    --mysql-password ) pass=$2; shift 2;;
    --php ) install_php=true; php_versions=($2); shift 2;;  # Allow setting PHP versions
    --phpmyadmin ) install_phpmyadmin=true; shift;;
    --phpmyadmin-password ) install_phpmyadmin_pass=$2; shift 2;;
    --supervisor ) install_supervisor=true; shift;;
    --lamp ) install_lamp=true; shift;;
    --lemp ) install_lemp=true; shift;;
    --remove ) remove_lamp=true; shift;;
    -h | --help ) show_help; exit;;
    * ) echo "Unknown option: $1"; show_help; exit 1;;
  esac
done

# Remove LAMP stack if --remove flag is passed
if [ "$remove_lamp" = true ]; then
  echo "Removing LAMP or LEMP stack..."
  remove_existing_installation
  exit 0
fi

# Check if LAMP or LEMP stack is already installed
if is_lamp_installed || is_lemp_installed; then
  if [ "$force_reinstall" = true ]; then
    echo "Forcing reinstallation..."
    remove_existing_installation
  else
    echo "LAMP or LEMP stack seems to be already installed. Use --force-reinstall flag to reinstall or --remove to uninstall."
    exit 1
  fi
fi

# Run the installation steps
run_update

# Install Web Server
if [[ "$install_lamp" = true ]] || [[ "$install_lemp" = true ]]; then
  if [[ "$web_server" == "apache" ]] || [[ "$install_lamp" = true ]]; then
    install_apache
  elif [[ "$web_server" == "nginx" ]] || [[ "$install_lemp" = true ]]; then
    install_nginx
  else
    echo "Unsupported web server: $web_server. Use 'apache' or 'nginx'."
    exit 1
  fi
fi

# Install MySQL
if [[ "$install_mysql" = true ]] || [[ "$install_lamp" = true ]] || [[ "$install_lemp" = true ]]; then
  install_mysql "$pass"
fi

# Install PHP
if [[ "$install_php" = true ]] || [[ "$install_lamp" = true ]] || [[ "$install_lemp" = true ]]; then
  for version in "${php_versions[@]}"; do
    install_php "$version"
  done
fi

# Install phpMyAdmin
if [[ "$install_phpmyadmin" = true ]] || [[ "$install_lamp" = true ]] || [[ "$install_lemp" = true ]]; then
  install_phpmyadmin "$install_phpmyadmin_pass"
fi

# Check if Supervisor is to be installed
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
if(ip == "")
then
  ip="localhost"
fi
echo "+-------------------------------------------+"
echo "|    Finish Auto Install and Setup LAMP    |"
echo "| Web Site: http://$ip/                    |"
echo "| PhpMyAdmin: http://$ip/phpmyadmin        |"
echo "| User: root || Pass: $pass                |"
echo "+-------------------------------------------+"
