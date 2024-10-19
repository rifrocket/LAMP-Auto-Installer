#!/bin/bash

# Default values
mysql_pass="testT8080"
php_versions=("8.2")
install_lamp=false
install_lemp=false
install_composer=false
install_supervisor=false
remove_web_server=false
force_reinstall=false

log_file="/var/log/lamp_install.log"

# Show help message
show_help() {
  cat << EOF
Usage: install-lamp.sh [options]

Options:
  --lamp                    Install LAMP stack (Apache, MySQL, PHP)
  --lemp                    Install LEMP stack (Nginx, MySQL, PHP)
  
Customization Options:
  -p, --mysql-password          Set MySQL root password (default: testT8080)
  -v, --php-version             Specify PHP version(s) to install (default: 8.2)
  -s, --supervisor              Install Supervisor (default: false, use flag to enable)
  -c, --composer                Install Composer (default: false, use flag to enable)
  -r, --remove                  Remove existing LAMP or LEMP stack (default: false, use flag to enable)
  --force-reinstall             Force reinstall of LAMP or LEMP stack if already installed
  -h, --help                    Show this help message

Examples:
  ./install-lamp.sh --lamp
  ./install-lamp.sh --lemp --php-version=8.1 --mysql-password=mysecurepassword
EOF
}

log() {
  echo "$1" | tee -a "$log_file"
}

# Pre-check if required tools are installed
check_prerequisites() {
  log "+--------------------------------------+"
  log "|  Checking Required Tools             |"
  log "+--------------------------------------+"
  
  required_tools=("curl" "debconf" "add-apt-repository")
  for tool in "${required_tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
      log "ERROR: Required tool '$tool' is not installed. Please install it and try again."
      exit 1
    fi
  done
  
  log "+--------------------------------------+"
  log "|  All Required Tools Are Available    |"
  log "+--------------------------------------+"
}

# Parse arguments
while [ "$1" != "" ]; do
  case "$1" in
    --lamp ) install_lamp=true; web_server="apache"; shift ;;
    --lemp ) install_lemp=true; web_server="nginx"; shift ;;
    -p | --mysql-password ) mysql_pass="$2"; shift 2 ;;
    -v | --php-version ) IFS=',' read -r -a php_versions <<< "$2"; shift 2 ;;
    -c | --composer ) install_composer=true; shift ;;
    -s | --supervisor ) install_supervisor=true; shift ;;
    -r | --remove ) remove_web_server=true; shift ;;
    --force-reinstall ) force_reinstall=true; shift ;;  
    -h | --help ) show_help; exit ;;
    * ) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# Get server IP
get_server_ip() {
  curl -s https://api.ipify.org || echo "localhost"
}

# Update system packages
update_system() {
  log "+--------------------------------------+"
  log "|     Updating system packages         |"
  log "+--------------------------------------+"
  sudo apt-get update -qq
  log "+--------------------------------------+"
  log "|     System packages updated          |"
  log "+--------------------------------------+"
}

# Install PHP and required extensions
install_php() {
  local php_version=$1
  log "+--------------------------------------+"
  log "|     Installing PHP $php_version      |"
  log "+--------------------------------------+"

  sudo apt-get install -y     unzip     openssl     php$php_version     libapache2-mod-php$php_version     php$php_version-mysql     php$php_version-curl     php$php_version-cli     php$php_version-mbstring     php$php_version-zip     php$php_version-xml     php$php_version-bcmath     php$php_version-json     php$php_version-fpm

  sudo update-alternatives --set php /usr/bin/php$php_version
}

# Install Apache
install_apache() {
  log "+--------------------------------------+"
  log "|     Installing Apache                |"
  log "+--------------------------------------+"
  sudo apt-get install -y apache2
  sudo ufw allow in "Apache Full"
  sudo systemctl start apache2
  sudo systemctl enable apache2
}

# Install Nginx
install_nginx() {
  log "+--------------------------------------+"
  log "|     Installing Nginx                 |"
  log "+--------------------------------------+"
  sudo apt-get install -y nginx
  sudo ufw allow 'Nginx Full'
  sudo systemctl enable nginx
  sudo systemctl start nginx
}

# Install MySQL
install_mysql() {
  local pass=$1
  log "+--------------------------------------+"
  log "|     Installing MySQL                 |"
  log "+--------------------------------------+"
  echo "mysql-server mysql-server/root_password password $pass" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $pass" | sudo debconf-set-selections
  sudo apt-get install -y mysql-server
}

# Main script starts here
check_prerequisites
update_system

# Install the chosen web server
if [[ "$install_lamp" = true ]]; then
  install_apache
  install_mysql "$mysql_pass"
  install_php "${php_versions[0]}"
fi

if [[ "$install_lemp" = true ]]; then
  install_nginx
  install_mysql "$mysql_pass"
  install_php "${php_versions[0]}"
fi

log "+--------------------------------------+"
log "|     Installation complete            |"
log "+--------------------------------------+"
