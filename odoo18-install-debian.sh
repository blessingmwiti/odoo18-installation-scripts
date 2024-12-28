#!/usr/bin/bash

# Color codes for echo statements
green="\e[32m"
red="\e[31m"
yellow="\e[33m"
reset="\e[0m"

# Function to print messages in color
echo_green() {
    echo -e "${green}$1${reset}"
}

echo_red() {
    echo -e "${red}$1${reset}"
}

echo_yellow() {
    echo -e "${yellow}$1${reset}"
}

# Start of script
echo_yellow "This script will install Odoo 18 on any Debian-based distro."
echo_yellow "You might be asked to enter ROOT password for SUPERUSER privileges."

echo_green "Updating system..."
sudo apt update -y || { echo_red "System update failed."; exit 1; }

echo_green "Installing Git, PostgreSQL, Python3.12, Wkhtmltopdf, and other dependencies..."
sudo apt install -y git postgresql postgresql-contrib python3.12 build-essential wget python3.12-dev \
    python3.12-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev \
    python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libtiff5-dev \
    libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev \
    libxcb1-dev wkhtmltopdf || { echo_red "Failed to install dependencies."; exit 1; }

echo_green "Dependencies installed successfully."

# Creating Odoo user
echo_green "Creating Odoo user..."
sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo || { echo_red "Failed to create Odoo user."; exit 1; }

# Setting up PostgreSQL
echo_green "Starting and enabling PostgreSQL..."
sudo systemctl start postgresql && sudo systemctl enable postgresql || { echo_red "Failed to start PostgreSQL."; exit 1; }


echo_green "Creating PostgreSQL user for Odoo..."
sudo -u postgres createuser --createdb odoo || { echo_red "Failed to create PostgreSQL user."; exit 1; }

# Setting up Odoo directory
echo_green "Setting up Odoo directory and permissions..."
sudo mkdir -p /opt/odoo/odoo-custom-addons
sudo chown -R odoo:odoo /opt/odoo

echo_green "Cloning Odoo 18 from GitHub..."
sudo -u odoo git clone --depth 1 --branch 18.0 https://www.github.com/odoo/odoo /opt/odoo/odoo || { echo_red "Failed to clone Odoo repository."; exit 1; }

# Creating Python virtual environment
echo_green "Creating virtual environment for Odoo..."
sudo -u odoo python3.12 -m venv /opt/odoo/odoo-venv || { echo_red "Failed to create virtual environment."; exit 1; }


echo_green "Installing Python dependencies..."
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install wheel
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install -r /opt/odoo/odoo/requirements.txt || { echo_red "Failed to install Python dependencies."; exit 1; }

# Creating Odoo configuration file
echo_green "Creating Odoo configuration file..."
cat <<EOF | sudo tee /etc/odoo.conf
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo/addons,/opt/odoo/odoo-custom-addons
EOF

# Setting up Odoo service
echo_green "Creating Odoo service file..."
cat <<EOF | sudo tee /etc/systemd/system/odoo.service
[Unit]
Description=Odoo18
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-venv/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf
StandardOutput=journal+console

[Install]
WantedBy=default.target
EOF


echo_green "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo_green "Starting and enabling Odoo service..."
sudo systemctl start odoo && sudo systemctl enable odoo || { echo_red "Failed to start Odoo service."; exit 1; }

# Finishing up
echo_green "Odoo 18 has been successfully installed and started."
echo_yellow "You can access Odoo at http://localhost:8069"
echo_green "Thank you for using this script!"
