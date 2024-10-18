#!/bin/bash

install_supervisor_service() {
  echo "Installing Supervisor..."
  sudo apt-get install -y supervisor > /dev/null 2>&1
  sudo systemctl enable supervisor
  sudo systemctl start supervisor
}
