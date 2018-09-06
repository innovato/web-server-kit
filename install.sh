#!/usr/bin/env bash

##
#  Innovato Webserver kit
##

# Configuring colors
end="\033[0m"
green="\033[0;32m"
red="\033[0;31m"

function green {
  echo -e "${green}${1}${end}"
}

function red {
  echo -e "${red}${1}${end}"
}

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    red 'This script can only be executed by root'
    exit 1
fi

# Check if web account exists
if [ ! -z "$(grep ^web: /etc/passwd)" ] && [ -z "$1" ]; then
    red "Error: user web exists"
    red 'Please remove web user before proceeding.'
    exit 1
fi

# This script has only been tested on Ubuntu, so we only support this OS
if [ $(head -n1 /etc/issue | cut -f 1 -d ' ') != 'Ubuntu' ]; then
    red "This script only works on Ubuntu"
    exit 1
fi

clear

# Display ascii and information
base64 -d <<<"H4sIAAAAAAAA/32PvQ6DMAyEd57iNlIJ0fIysEQ6hJSh6kYRUx6+5xgQSxMr5+T8OT8AURtXtUHgowJmxUmqS0EcKuGVQZHm00jraonoiidMLWs1q0a65eQ97DURo8DA4riVRTKXOw6NtENimezK3q2m+vH7+EdOafmmdU8rPu8Nr37ADyO2JGVPAQAA" | gunzip
echo -e "\n\n"
echo -e "This software will install Nginx, multiple PHP versions, MySQL and some other basic webserver tools. It also will do some basic configuration, like increasing the memory limit, install common extensions etc."
echo -e "You will be prompted to install some software. You won't be prompted to install essential tools. \n"
echo -e "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
echo -e "\n"

# Array of software to install
array=( php7.2 php7.1 php7.0 php5.6 mysql-server mysql-client composer npm yarn )
install=()
dontInstall=()

# Asking what software to install
for software in "${array[@]}"
do
  while true; do
      read -p "Do you wish to install $software? [Y/n] " yn
      case $yn in
          [yY][eE][sS]|[yY]|"" ) install+=("$software") ; break;;
          [Nn][Oo]|[nN] ) dontInstall+=("$software"); break;;
          * ) echo "Please answer yes or no.";;
      esac
  done
done

# Confirm
echo -e "\nYou have selected the following software to install:"
for software in "${install[@]}"
do
  green "- $software"
done

echo -e "\nThe following software won't be installed:"
for software in "${dontInstall[@]}"
do
  red "- $software"
done
echo -e "\n"
while true; do
    read -p "Is this correct? [y/n] " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "Aborted"; exit; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

timezone=$(cat /etc/timezone)

while true; do
    read -p "Your current timezone is set to $timezone, do you wish to update it? [y/N] " yn
    case $yn in
        [yY][eE][sS]|[yY] ) sudo dpkg-reconfigure tzdata; break;;
        [Nn][Oo]|[nN]|"" ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Running system upgrade"
{
  # Add universal repository
  add-apt-repository universe

  # Update Package List
  apt-get update

  # Update System Packages
  apt-get dist-upgrade -y
} &> /dev/null

echo "Setting locale to en_US.UTF-8"
{
  # Force Locale
  echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
  locale-gen en_US.UTF-8
} &> /dev/null

while true; do
    read -p "Would you like sudoers to be able to run sudo commands without getting password prompts? [ONLY RECOMMENDED IF YOU KNOW WHAT YOU ARE DOING] [y/N] " yn
    case $yn in
        [yY][eE][sS]|[yY] ) sudoWithoutPass="yes"; break;;
        [Nn][Oo]|[nN]|"" ) sudoWithoutPass="no" break;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [[ $sudoWithoutPass == "yes" ]]; then
  # Run sudo commands without password prompt
  sed -i 's/%sudo/#%sudo/g' /etc/sudoers
  echo >> /etc/sudoers "%sudo   ALL=(ALL) NOPASSWD: ALL"
fi

echo "Installing essential packages"
{
  # Install Some PPAs
  apt-get install -y software-properties-common curl

  apt-add-repository ppa:ondrej/php -y

  # Update Package Lists
  apt-get update

  # Install Some Basic Packages
  apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev libpng-dev ntp unzip \
  make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin \
  pv cifs-utils mcrypt bash-completion zsh graphviz
} &> /dev/null

for software in "${install[@]}"
do
  if [[ $software == "php7.2" ]]; then
    echo "Installing PHP 7.2"
    {
      # PHP 7.2
      apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
      php7.2-cli php7.2-dev \
      php7.2-pgsql php7.2-sqlite3 php7.2-gd \
      php7.2-curl php7.2-memcached \
      php7.2-imap php7.2-mysql php7.2-mbstring \
      php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
      php7.2-intl php7.2-readline php7.2-ldap \
      php-xdebug php-pear
    } &> /dev/null
  fi

  if [[ $software == "php7.1" ]]; then
    echo "Installing PHP 7.1"
    {
      # PHP 7.1
      apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
      php7.1-cli php7.1-dev \
      php7.1-pgsql php7.1-sqlite3 php7.1-gd \
      php7.1-curl php7.1-memcached \
      php7.1-imap php7.1-mysql php7.1-mbstring \
      php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
      php7.1-intl php7.1-readline
    } &> /dev/null
  fi

  if [[ $software == "php7.0" ]]; then
    echo "Installing PHP 7.0"
    {
      # PHP 7.0
      apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
      php7.0-cli php7.0-dev \
      php7.0-pgsql php7.0-sqlite3 php7.0-gd \
      php7.0-curl php7.0-memcached \
      php7.0-imap php7.0-mysql php7.0-mbstring \
      php7.0-xml php7.0-zip php7.0-bcmath php7.0-soap \
      php7.0-intl php7.0-readline
    } &> /dev/null
  fi

  if [[ $software == "php5.6" ]]; then
    echo "Installing PHP 5.6"
    {
      # PHP 5.6
      apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
      php5.6-cli php5.6-dev \
      php5.6-pgsql php5.6-sqlite3 php5.6-gd \
      php5.6-curl php5.6-memcached \
      php5.6-imap php5.6-mysql php5.6-mbstring \
      php5.6-xml php5.6-zip php5.6-bcmath php5.6-soap \
      php5.6-intl php5.6-readline php5.6-mcrypt
    } &> /dev/null
  fi
done

while true; do
  read -p "What PHP version do you want to set as default? [7.2]" phpversion
  case $phpversion in
      7.2|"" ) defaultVersion="7.2"; break;;
      7.1 ) defaultVersion="7.1"; break;;
      7.0 ) defaultVersion="7.0"; break;;
      5.6 ) defaultVersion="5.6"; break;;
      * ) echo "Please type a valid version";;
    esac
done

echo "Setting default PHP version"
{
  update-alternatives --set php /usr/bin/php$defaultVersion
  update-alternatives --set php-config /usr/bin/php-config$defaultVersion
  update-alternatives --set phpize /usr/bin/phpize$defaultVersion
} &> /dev/null

# Install Composer
if [[ " ${install[@]} " =~ " composer " ]]; then
  echo "Installing composer"
  {
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
  } &> /dev/null
fi

while true; do
  read -p "What size should be the memory limit of PHP CLI? [1024M]" value
  case $value in
      *M ) memoryLimit="$value"; break;;
      "" ) memoryLimit="1024M"; break;;
      * ) echo "Please type a valid value, e.g.: 2048M";;
    esac
done

# Set Some PHP CLI Settings
if [[ " ${install[@]} " =~ " php7.2 " ]]; then
  sudo sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.2/cli/php.ini
fi
if [[ " ${install[@]} " =~ " php7.1 " ]]; then
  sudo sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.1/cli/php.ini
fi
if [[ " ${install[@]} " =~ " php7.0 " ]]; then
  sudo sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.0/cli/php.ini
fi
if [[ " ${install[@]} " =~ " php5.6 " ]]; then
  sudo sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/5.6/cli/php.ini
fi

fpmPackages=""
# Install Nginx & PHP-FPM
for software in "${install[@]}"
do
  if [[ " ${install[@]} " =~ " php7.2 " ]]; then
    fpmPackages="$fpmPackages php7.2-fpm"
  fi
  if [[ " ${install[@]} " =~ " php7.1 " ]]; then
    fpmPackages="$fpmPackages php7.1-fpm"
  fi
  if [[ " ${install[@]} " =~ " php7.0 " ]]; then
    fpmPackages="$fpmPackages php7.0-fpm"
  fi
  if [[ " ${install[@]} " =~ " php5.6 " ]]; then
    fpmPackages="$fpmPackages php5.6-fpm"
  fi
done

echo "Installing PHP-FPM"
{
  apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  nginx $fpmPackages
} &> /dev/null

while true; do
  read -p "What size should be the upload_max_filesize of PHP-FPM? [1024M]" value
  case $value in
      *M ) uploadMaxFileSize="$value"; break;;
      "" ) uploadMaxFileSize="1024M"; break;;
      * ) echo "Please type a valid value, e.g.: 2048M";;
    esac
done

while true; do
  read -p "What size should be the post_max_size of PHP-FPM? [1024M]" value
  case $value in
      *M ) postMaxSize="$value"; break;;
      "" ) postMaxSize="1024M"; break;;
      * ) echo "Please type a valid value, e.g.: 2048M";;
    esac
done

while true; do
  read -p "What size should be the memory_limit of PHP-FPM? [1024M]" value
  case $value in
      *M ) memoryLimit="$value"; break;;
      "" ) memoryLimit="1024M"; break;;
      * ) echo "Please type a valid value, e.g.: 2048M";;
    esac
done

if [[ " ${install[@]} " =~ " php7.2 " ]]; then
  sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
  sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.2/fpm/php.ini
  sed -i "s/upload_max_filesize = .*/upload_max_filesize = $uploadMaxFileSize/" /etc/php/7.2/fpm/php.ini
  sed -i "s/post_max_size = .*/post_max_size = $postMaxSize/" /etc/php/7.2/fpm/php.ini
fi

if [[ " ${install[@]} " =~ " php7.1 " ]]; then
  sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
  sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.1/fpm/php.ini
  sed -i "s/upload_max_filesize = .*/upload_max_filesize = $uploadMaxFileSize/" /etc/php/7.1/fpm/php.ini
  sed -i "s/post_max_size = .*/post_max_size = $postMaxSize/" /etc/php/7.1/fpm/php.ini
fi

if [[ " ${install[@]} " =~ " php7.0 " ]]; then
  sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
  sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/7.0/fpm/php.ini
  sed -i "s/upload_max_filesize = .*/upload_max_filesize = $uploadMaxFileSize/" /etc/php/7.0/fpm/php.ini
  sed -i "s/post_max_size = .*/post_max_size = $postMaxSize/" /etc/php/7.0/fpm/php.ini
fi

if [[ " ${install[@]} " =~ " php5.6 " ]]; then
  sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/5.6/fpm/php.ini
  sed -i "s/memory_limit = .*/memory_limit = $memoryLimit/" /etc/php/5.6/fpm/php.ini
  sed -i "s/upload_max_filesize = .*/upload_max_filesize = $uploadMaxFileSize/" /etc/php/5.6/fpm/php.ini
  sed -i "s/post_max_size = .*/post_max_size = $postMaxSize/" /etc/php/5.6/fpm/php.ini
fi

# Copy fastcgi_params to Nginx because they broke it on the PPA
cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

echo "Adding user \"web\""
{
  # Add user
  adduser --disabled-password --gecos "" web
} &> /dev/null

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user web;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

echo "Changing user and group in PHP-FPM pools"

if [[ " ${install[@]} " =~ " php7.2 " ]]; then
  sed -i "s/user = www-data/user = web/" /etc/php/7.2/fpm/pool.d/www.conf
  sed -i "s/group = www-data/group = web/" /etc/php/7.2/fpm/pool.d/www.conf
fi

if [[ " ${install[@]} " =~ " php7.1 " ]]; then
  sed -i "s/user = www-data/user = web/" /etc/php/7.1/fpm/pool.d/www.conf
  sed -i "s/group = www-data/group = web/" /etc/php/7.1/fpm/pool.d/www.conf

  sed -i "s/listen\.owner.*/listen.owner = web/" /etc/php/7.1/fpm/pool.d/www.conf
  sed -i "s/listen\.group.*/listen.group = web/" /etc/php/7.1/fpm/pool.d/www.conf
  sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.1/fpm/pool.d/www.conf
fi

if [[ " ${install[@]} " =~ " php7.0 " ]]; then
  sed -i "s/user = www-data/user = web/" /etc/php/7.0/fpm/pool.d/www.conf
  sed -i "s/group = www-data/group = web/" /etc/php/7.0/fpm/pool.d/www.conf

  sed -i "s/listen\.owner.*/listen.owner = web/" /etc/php/7.0/fpm/pool.d/www.conf
  sed -i "s/listen\.group.*/listen.group = web/" /etc/php/7.0/fpm/pool.d/www.conf
  sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf
fi

if [[ " ${install[@]} " =~ " php5.6 " ]]; then
  sed -i "s/user = www-data/user = web/" /etc/php/5.6/fpm/pool.d/www.conf
  sed -i "s/group = www-data/group = web/" /etc/php/5.6/fpm/pool.d/www.conf

  sed -i "s/listen\.owner.*/listen.owner = web/" /etc/php/5.6/fpm/pool.d/www.conf
  sed -i "s/listen\.group.*/listen.group = web/" /etc/php/5.6/fpm/pool.d/www.conf
  sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/5.6/fpm/pool.d/www.conf
fi

echo "Restarting services"
{
  service nginx restart
  if [[ " ${install[@]} " =~ " php7.2 " ]]; then
    service php7.2-fpm restart
  fi
  if [[ " ${install[@]} " =~ " php7.1 " ]]; then
    service php7.1-fpm restart
  fi
  if [[ " ${install[@]} " =~ " php7.0 " ]]; then
    service php7.0-fpm restart
  fi
  if [[ " ${install[@]} " =~ " php5.6 " ]]; then
    service php5.6-fpm restart
  fi
} &> /dev/null

echo "Adding web user to www-data group"
{
  # Add web user to www-data
  usermod -a -G www-data web
  id web
  groups web
} &> /dev/null

if [[ " ${install[@]} " =~ " yarn " ]]; then
  echo "Installing yarn"
  {
    apt-get install -y nodejs
    /usr/bin/npm install -g yarn
  } &> /dev/null
fi

if [[ " ${install[@]} " =~ " npm " ]]; then
  echo "Installing npm"
  {
    apt-get install -y nodejs
    /usr/bin/npm install -g npm
  } &> /dev/null
fi

# Install MySQL
if [[ " ${install[@]} " =~ " mysql-server " ]]; then
  while true; do
      read -s -p "Choose a MySQL-server root password: " password
      echo
      read -s -p "Password (again): " password2
      echo
      [ "$password" = "$password2" ] && break
      echo "The passwords didn't match, try again."
  done

  echo "mysql-server mysql-server/root_password password $password" | debconf-set-selections
  echo "mysql-server mysql-server/root_password_again password $password" | debconf-set-selections

  echo "Installing MySQL-server"
  {
    apt-get install -y mysql-server

    # Configure MySQL Password Lifetime
    echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
  } &> /dev/null

  # Configure MySQL Remote Access
  while true; do
      read -p "Do you want the root user on MySQL-server to be accessible for everyone? [y/N] " yn
      case $yn in
          [yY][eE][sS]|[yY] ) remote="yes" ; break;;
          [Nn][Oo]|[nN]|"" ) remote="no"; break;;
          * ) echo "Please answer yes or no.";;
      esac

      if [[ $remote == "yes" ]]; then
        mysql --user="root" --password="$password" -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '$password' WITH GRANT OPTION;"
        service mysql restart
      fi
  done

  echo "Adding timezone support to MySQL"
  {
    # Add Timezone Support To MySQL
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=$password mysql
    service mysql restart
  } &> /dev/null
fi

echo "Installing memcached and redis-server"
{
  # Install Memcached & redis-server
  apt-get install -y redis-server memcached

  apt-get -y upgrade
} &> /dev/null

if [[ " ${install[@]} " =~ " composer " ]]; then
  # Add Composer Global Bin To Path
  printf "\nPATH=\"$(sudo su - web -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/web/.profile
fi

while true; do
  read -p "Would you like to add SSH keys to authorized_keys? [Y/n] " yn
  case $yn in
      [yY][eE][sS]|[yY]|"" ) sshKeys="yes" ; break;;
      [Nn][Oo]|[nN] ) sshKeys="no"; break;;
      * ) echo "Please answer yes or no.";;
  esac
done

if [[ $sshKeys = "yes" ]]; then
  mkdir -p ~/.ssh
  nano ~/.ssh/authorized_keys
  cd ~/
  echo "File has been saved to ~/.ssh/authorized_keys"
fi

while true; do
  read -p "The installation is done. Would you like to reboot the server? [Y/n] " yn
  case $yn in
      [yY][eE][sS]|[yY]|"" ) rebootServer="yes"; break;;
      [Nn][Oo]|[nN] ) rebootServer="no" break;;
      * ) echo "Please answer yes or no.";;
  esac
done

echo "Cleaning up..."
{
  # Clean Up
  apt-get -y autoremove
  apt-get -y clean
  chown -R web:web /home/web
  rm -- "$0"
} &> /dev/null

if [[ $sshKeys = "yes" ]]; then
  reboot
fi
