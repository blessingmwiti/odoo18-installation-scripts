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

echo_green "Updating system..."
sudo apt update -y || {
    echo_red "System update failed."
    exit 1
}

echo_yellow "Checking for Python 3.12 installation..."

if ! python3.12 --version &>/dev/null; then
    echo_red "Python 3.12 not found. Attempting to install it..."

    # Add deadsnakes PPA for Ubuntu-based systems
    if [[ "$(lsb_release -is)" == "Ubuntu" || "$(lsb_release -is)" == "LinuxMint" ]]; then
        echo_green "Adding deadsnakes PPA..."
        sudo add-apt-repository ppa:deadsnakes/ppa -y || {
            echo_red "Failed to add deadsnakes PPA."
            exit 1
        }
        sudo apt update -y
    fi

    # Install Python 3.12
    echo_green "Installing Python 3.12..."
    sudo apt install python3.12 python3.12-venv python3.12-dev -y || {
        echo_red "Failed to install Python 3.12 from repository. Installing from source..."

        # Download and build Python 3.12 from source
        cd /usr/src/
        sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz || {
            echo_red "Failed to download Python source."
            exit 1
        }
        sudo tar xzf Python-3.12.0.tgz
        cd Python-3.12.0
        sudo ./configure --enable-optimizations
        sudo make altinstall || {
            echo_red "Failed to compile and install Python 3.12."
            exit 1
        }

        # Verify installation
        python3.12 --version &>/dev/null || {
            echo_red "Python 3.12 installation failed."
            exit 1
        }
    }

else
    echo_green "Python 3.12 is already installed."
fi

echo_green "Installing dependencies..."

# Install build dependencies
sudo apt install -y build-essential libssl-dev libffi-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libxml2-dev libxmlsec1-dev liblzma-dev python3.12-venv python3.12-dev || {
    echo_red "Failed to install build dependencies."
    exit 1
}

echo_green "Installing Wkhtmltopdf..."

sudo apt install -y wkhtmltopdf || {
    echo_red "Failed to install Wkhtmltopdf."
    exit 1
}

echo_green "Dependencies installed successfully."

# Creating Odoo user
echo_green "Creating Odoo user..."
sudo adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo || {
    echo_red "Failed to create Odoo user."
    exit 1
}

echo_green "Installing Postgresql..."

sudo apt install postgresql postgresql-contrib -y || {
    echo_red "Failed to install PostgreSQL."
    exit 1
}

# Setting up PostgreSQL
echo_green "Starting and enabling PostgreSQL..."
sudo systemctl start postgresql && sudo systemctl enable postgresql || {
    echo_red "Failed to start PostgreSQL."
    exit 1
}

echo_green "Checking if PostgreSQL user 'odoo' exists..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" | grep -q 1; then
    echo_yellow "PostgreSQL user 'odoo' already exists."
else
    echo_green "Creating PostgreSQL user for Odoo..."
    sudo -u postgres createuser --createdb odoo || {
        echo_red "Failed to create PostgreSQL user."
        exit 1
    }
fi

# Setting up Odoo directory
echo_green "Setting up Odoo directory and permissions..."
sudo mkdir -p /opt/odoo/odoo-custom-addons
sudo chown -R odoo:odoo /opt/odoo

echo_green "Cloning Odoo 18 from GitHub..."
sudo -u odoo git clone --depth 1 --branch 18.0 https://www.github.com/odoo/odoo /opt/odoo/odoo || {
    echo_red "Failed to clone Odoo repository."
    exit 1
}

# Creating Python virtual environment
echo_green "Creating virtual environment for Odoo..."
sudo -u odoo python3.12 -m venv /opt/odoo/odoo-venv || {
    echo_red "Failed to create virtual environment."
    exit 1
}

echo_green "Installing Python dependencies..."
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install wheel
sudo -u odoo /opt/odoo/odoo-venv/bin/pip install -r /opt/odoo/odoo/requirements.txt || {
    echo_red "Failed to install Python dependencies."
    exit 1
}

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
sudo systemctl start odoo && sudo systemctl enable odoo || {
    echo_red "Failed to start Odoo service."
    exit 1
}

# Finishing up
echo_green "Odoo 18 has been successfully installed and started."
echo_yellow "You can access Odoo at http://localhost:8069"
echo_green "Thank you for using this script!"
