#!/bin/bash

install_phpmyadmin() {
  local pass=$1
  echo "Installing PhpMyAdmin..."
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | sudo debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | sudo debconf-set-selections
  sudo apt-get install -y phpmyadmin php-mbstring php-gettext > /dev/null 2>&1
  sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
}
