#!/bin/sh
# Auto Install and Setup LAMP #
# Example: sudo bash lamp-install.sh -p MyPassword
# By Saleh7 - https://github.com/Saleh7

E=`tput setaf 1`
G=`tput setaf 2`
A=`tput setaf 3`
C=`tput setaf 6`
B=`tput bold`
R=`tput sgr0`

help() {
echo "
 ${B}${A}# Auto Install and Setup LAMP #${R}

 ${B}${C}# Apache - MySQL - PHP - phpMyAdmin #${R}

 Example: ${G}sudo bash lamp-install.sh${G} -p${R} ${E}MyPassword123@!-${R}
 ${C}Default:${R} ${G}sudo bash lamp-install.sh${R}${C} | Password:testT8080${R}"
}

while [ "$1" != "" ]; do
  case "$1" in
    -p  | --password ) pass=$2; shift 2;;
    -h  | --help )     echo "$(help)";
    exit; shift; break;;
  esac
done

echo "${B}${A}Running Lamp.sh...${R}"

# System Update
echo "+-------------------------------------------+"
echo "|                 Update                    |"
echo "+-------------------------------------------+"
apt-get -qq update

# Install dependencies
echo "+-------------------------------------------+"
echo "|     Installing curl and expect            |"
echo "+-------------------------------------------+"
sudo apt-get install -y curl expect apache2 > /dev/null 2>&1

if [ -z "$pass" ]
then
  pass="testT8080"
fi
ip=$(curl -s https://api.ipify.org)

# Install Apache
echo "+-------------------------------------------+"
echo "|         Installing Apache                 |"
echo "+-------------------------------------------+"
sudo apt-get install -y apache2 > /dev/null 2>&1
sudo systemctl start apache2
sudo systemctl enable apache2

sudo tee /var/www/html/index.html > /dev/null <<END
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Apache!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Apache!</h1>
<br/>
<a href="http://$ip/info.php">Php - info</a>.
</body>
</html>
END

sudo tee /var/www/html/info.php > /dev/null <<END
<?php
phpinfo();
?>
END

# Install MySQL
echo "+-------------------------------------------+"
echo "|       Installing MySQL Server             |"
echo "+-------------------------------------------+"
echo "mysql-server mysql-server/root_password password $pass" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $pass" | debconf-set-selections
sudo apt-get install -y mysql-server > /dev/null 2>&1

expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Enter password for user root:\"
send \"$pass\r\"

expect \"Press y|Y for Yes, any other key for No:\"
send \"y\r\"

expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
send \"2\r\"

expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"n\r\"

expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect eof
" > /dev/null 2>&1

# Install PHP 8.2 and necessary extensions
echo "+-------------------------------------------+"
echo "|             Installing PHP 8.2            |"
echo "+-------------------------------------------+"
sudo apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-mysql php8.2-curl > /dev/null 2>&1

# Enable PHP 8.2 module for Apache
sudo a2enmod php8.2
sudo systemctl restart apache2

# Configure PHP 8.2 settings
sudo sed -i 's/;date.timezone =/date.timezone = Europe\/Berlin/' /etc/php/8.2/apache2/php.ini
sudo sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.2/apache2/php.ini
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 200M/' /etc/php/8.2/apache2/php.ini
sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php/8.2/apache2/php.ini

# Install PhpMyAdmin
echo "+-------------------------------------------+"
echo "|       Installing PhpMyAdmin               |"
echo "+-------------------------------------------+"
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $pass" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $pass" | debconf-set-selections
sudo apt-get install -y phpmyadmin php-mbstring php-gettext > /dev/null 2>&1

sudo ln -s /usr/share/phpmyadmin/ /var/www/html/

# Restart services
echo "+-------------------------------------------+"
echo "|    Restarting PHP 8.2 and Apache services |"
echo "+-------------------------------------------+"
sudo systemctl restart apache2

# Display completion message
echo "+-------------------------------------------+"
echo "|    ${B}${A}Finish Auto Install and Setup LAMP${R}      |"
echo "|                                           |"
echo "| Web Site: http://$ip/"
echo "| PhpMyAdmin: http://$ip/phpmyadmin"
echo "| User: ${E}root${R} || Pass: ${E}$pass${R}"
echo "| Test PHP: http://$ip/info.php"
echo "| ${E}Warning: Delete info.php for security${R}         |"
echo "+-------------------------------------------+"

exit 0
