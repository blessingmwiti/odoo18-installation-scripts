#!/usr/bin/bash

echo "This script will install Odoo 18 on any debian based distro"

echo "You might be asked to enter ROOT password for SUPERUSER privileges, please do so"

echo "Updating system..."

sudo apt update -y

echo "Installing Git, PostgresQl, Python3.12, Wkhtmltopdf and other dependencies..."

if (sudo apt install git postgresql postgresql-contrib python3.12 build-essential wget python3.12-dev python3.12-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev wkhtmltopdf -y) {
    echo "Dependencies installed successfully"
} else {
    echo "Failed to install dependencies"
    exit 1
}

clear

echo "Creating Odoo user..."

sudo adduser odoo

echo "Starting and enabling PostgresQl..."

sudo systemctl start postgresql && sudo systemctl enable postgresql

echo "Changing default password for Postgres..."

echo "Please enter the new password for Postgres user"

sudo passwd postgres

echo "Postgres password changed successfully"

sleep 3

clear

echo "Switching to Postgres user..."

sudo su postgres

echo "Creating database user named odoo with relevant permissions..."

createuser odoo

psql

ALTER USER odoo WITH CREATEDB;

\q

exit

echo "Postgres user created successfully"

sleep 3

clear

echo "Creating directory for Odoo and setting the owner to odoo user..."

sudo mkdir -p /opt/odoo/odoo

sudo chown -R odoo /opt/odoo

sudo chgrp -R odoo /opt/odoo

echo "Switching to odoo user..."

sudo su odoo

echo "Clone Odoo 18 from Github..."

git clone https://www.github.com/odoo/odoo --depth 1 --branch 18.0 /opt/odoo/odoo

clear

echo "Creating virtual environment for Odoo..."

cd /opt/odoo/

python3.12 -m venv odoo-venv

echo "Activating virtual environment..."

source odoo-venv/bin/activate

echo "Installing dependencies..."

pip3 install wheel

pip3 install -r odoo/requirements.txt

echo "Deactivating virtual environment..."

deactivate

echo "Creating directory for custom addons..."

mkdir /opt/odoo/odoo-custom-addons

echo "Switching back user..."

exit

echo "Creating Odoo configuration file..."

sudo echo "[options]" >> /etc/odoo.conf

sudo echo "admin_passwd = admin" >> /etc/odoo.conf

sudo echo "db_host = False" >> /etc/odoo.conf

sudo echo "db_port = False" >> /etc/odoo.conf

sudo echo "db_user = odoo" >> /etc/odoo.conf

sudo echo "db_password = False" >> /etc/odoo.conf

sudo echo "addons_path = /opt/odoo/odoo/addons,/opt/odoo/odoo-custom-addons" >> /etc/odoo.conf

echo "Creating Odoo service..."

sudo echo "[Unit]" >> /etc/systemd/system/odoo.service

sudo echo "Description=Odoo18" >> /etc/systemd/system/odoo.service

sudo echo "Requires=postgresql.service" >> /etc/systemd/system/odoo.service

sudo echo "After=network.target postgresql.service" >> /etc/systemd/system/odoo.service

sudo echo "" >> /etc/systemd/system/odoo.service

sudo echo "[Service]" >> /etc/systemd/system/odoo.service

sudo echo "Type=simple" >> /etc/systemd/system/odoo.service

sudo echo "SyslogIdentifier=odoo" >> /etc/systemd/system/odoo.service

sudo echo "PermissionsStartOnly=true" >> /etc/systemd/system/odoo.service

sudo echo "User=odoo" >> /etc/systemd/system/odoo.service

sudo echo "Group=odoo" >> /etc/systemd/system/odoo.service

sudo echo "ExecStart=/opt/odoo/odoo-venv/bin/python3 /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf" >> /etc/systemd/system/odoo.service

sudo echo "StandardOutput=journal+console" >> /etc/systemd/system/odoo.service

sudo echo "" >> /etc/systemd/system/odoo.service

sudo echo "[Install]" >> /etc/systemd/system/odoo.service

sudo echo "WantedBy=default.target" >> /etc/systemd/system/odoo.service

echo "Reloading systemd daemon..."

sudo systemctl daemon-reload

echo "Starting and enabling Odoo service..."

sudo systemctl start odoo && sudo systemctl enable odoo

echo "Odoo 18 has been successfully installed and started"

echo "You can access Odoo at http://localhost:8069"

echo "Thank you for using this script"

echo "Goodbye"
