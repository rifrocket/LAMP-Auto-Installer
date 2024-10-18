#!/bin/bash
source utils.sh
source apache.sh
source mysql.sh
source php.sh
source phpmyadmin.sh

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

# Check if the script has been run before
if [ -f /var/www/html/info.php ]; then
  echo "LAMP stack is already installed. Do you want to reinstall? (y/n)"
  read -r choice
  if [ "$choice" != "y" ]; then
    echo "Aborting."
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
install_php "${php_versions[@]}"

# Optional Supervisor installation
if [ "$install_supervisor" = true ]; then
  source supervisor.sh
  install_supervisor_service
fi

install_phpmyadmin "$pass"

echo "Installation complete. Access your server at http://$(get_server_ip)"
