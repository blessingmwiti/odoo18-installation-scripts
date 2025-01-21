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
echo_yellow "This script will install Odoo 18 on any Ubuntu-based distro."
echo_yellow "You might be asked to enter ROOT password for SUPERUSER privileges."

# Update system
echo_green "Updating system..."
sudo apt update -y || {
    echo_red "System update failed. Check your internet connection or package manager."
    
}

# Check for Python 3.12 installation
echo_yellow "Checking for Python 3.12 installation..."
if ! python3.12 --version &>/dev/null; then
    echo_red "Python 3.12 not found. Installing..."

    # Add deadsnakes PPA and install Python 3.12
    if [[ "$(lsb_release -is)" == "Ubuntu" || "$(lsb_release -is)" == "LinuxMint" ]]; then
        echo_green "Adding deadsnakes PPA..."
        sudo add-apt-repository ppa:deadsnakes/ppa -y || {
            echo_red "Failed to add deadsnakes PPA."
            
        }
        sudo apt update -y
    fi

    echo_green "Installing Python 3.12..."
    sudo apt install python3.12 python3.12-venv python3.12-dev -y || {
        echo_red "Failed to install Python 3.12 from repository. Attempting to build from source..."

        cd /usr/src/
        sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz || {
            echo_red "Failed to download Python source."
            
        }
        sudo tar xzf Python-3.12.0.tgz
        cd Python-3.12.0
        sudo ./configure --enable-optimizations
        sudo make altinstall || {
            echo_red "Failed to compile and install Python 3.12."
            
        }
    }
else
    echo_green "Python 3.12 is already installed."
fi

# Install build dependencies
echo_green "Installing dependencies..."
sudo apt install -y build-essential wget python3.12-dev python3.12-venv python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev libxslt1-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev || {
    echo_red "Failed to install build dependencies."
    
}

# Install Wkhtmltopdf
echo_green "Installing Wkhtmltopdf..."
sudo apt install -y wkhtmltopdf || {
    echo_red "Failed to install Wkhtmltopdf."
    
}

# Create Odoo user
echo_green "Checking if Odoo user exists..."
if id "odoo" &>/dev/null; then
    echo_yellow "Odoo user already exists. Skipping creation."
else
    echo_green "Creating Odoo user..."
    sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo || {
        echo_red "Failed to create Odoo user."
        
    }
fi

# Install PostgreSQL
echo_green "Installing PostgreSQL..."
sudo apt install postgresql postgresql-contrib -y || {
    echo_red "Failed to install PostgreSQL."
    
}

# Start and enable PostgreSQL
echo_green "Starting and enabling PostgreSQL..."
sudo systemctl start postgresql && sudo systemctl enable postgresql || {
    echo_red "Failed to start PostgreSQL."
    
}

# Create PostgreSQL user for Odoo
echo_green "Checking if PostgreSQL user 'odoo' exists..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" | grep -q 1; then
    echo_yellow "PostgreSQL user 'odoo' already exists."
else
    echo_green "Creating PostgreSQL user for Odoo..."
    sudo -u postgres createuser --createdb odoo || {
        echo_red "Failed to create PostgreSQL user."
        
    }
fi

# Set up Odoo directories
echo_green "Setting up Odoo directories..."
[ -d "/opt/odoo" ] || sudo mkdir /opt/odoo
[ -d "/opt/odoo/odoo-custom-addons" ] || sudo mkdir /opt/odoo/odoo-custom-addons
sudo chown -R odoo:odoo /opt/odoo

# Clone Odoo repository
echo_green "Cloning Odoo repository..."
if [ -d "/opt/odoo/odoo" ]; then
    echo_yellow "Odoo repository already cloned. Skipping."
else
    sudo -u odoo git clone --depth 1 --branch 15.0 https://github.com/odoo/odoo /opt/odoo/odoo || {
        echo_red "Failed to clone Odoo repository."
        
    }
fi

# Create virtual environment
echo_green "Setting up Python virtual environment..."
if [ -d "/opt/odoo/odoo-venv" ]; then
    echo_yellow "Virtual environment already exists. Skipping creation."
else
    sudo -u odoo python3.12 -m venv /opt/odoo/odoo-venv || {
        echo_red "Failed to create virtual environment."
        
    }
fi

# Install Python dependencies
echo_green "Installing Python dependencies..."
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install wheel
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install -r /opt/odoo/odoo/requirements.txt || {
    echo_red "Failed to install Python dependencies."
    
}

# Create Odoo configuration file
echo_green "Creating Odoo configuration file..."
if [ -f "/etc/odoo.conf" ]; then
    echo_yellow "Odoo configuration file already exists. Skipping."
else
    cat <<EOF | sudo tee /etc/odoo.conf
[options]
admin_passwd = admin
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = /opt/odoo/odoo/addons,/opt/odoo/odoo-custom-addons
EOF
fi

# Set up Odoo systemd service
echo_green "Setting up Odoo systemd service..."
if [ -f "/etc/systemd/system/odoo.service" ]; then
    echo_yellow "Odoo service file already exists. Skipping."
else
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF
fi

# Start and enable Odoo service
echo_green "Starting Odoo service..."
sudo systemctl daemon-reload
sudo systemctl start odoo && sudo systemctl enable odoo || {
    echo_red "Failed to start Odoo service."
    
}

clear

echo_yellow "Enter postgres user password. Kindly remember it."
sudo passwd postgres

sleep 2

clear

echo_yellow "Enter Odoo user password. Kindly remember it."
sudo passwd odoo

sleep 2

clear

# Completion message
echo_green "Odoo 18 installation complete. Access it at http://localhost:8069. Change localhost to your server IP if needed."
