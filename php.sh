#!/bin/bash

install_php() {
  local versions=("$@")
  echo "Installing PHP versions: ${versions[*]}..."

  for version in "${versions[@]}"; do
    sudo apt-get install -y php$version libapache2-mod-php$version php${version}-mysql php${version}-curl > /dev/null 2>&1
    sudo a2enmod php$version
  done

  sudo systemctl restart apache2
}
