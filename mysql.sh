#!/bin/bash

install_mysql() {
  local pass=$1
  echo "Installing MySQL..."
  echo "mysql-server mysql-server/root_password password $pass" | sudo debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $pass" | sudo debconf-set-selections
  sudo apt-get install -y mysql-server > /dev/null 2>&1
  sudo systemctl start mysql
  sudo systemctl enable mysql
}
