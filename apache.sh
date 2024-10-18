#!/bin/bash

install_apache() {
  echo "Installing Apache..."
  sudo apt-get install -y apache2 > /dev/null 2>&1
  sudo systemctl start apache2
  sudo systemctl enable apache2

  sudo tee /var/www/html/index.html > /dev/null <<END
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Apache!</title>
</head>
<body>
<h1>Apache is installed!</h1>
</body>
</html>
END
}
