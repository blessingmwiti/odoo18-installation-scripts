# Odoo 18 Installation Scripts

Bash scripts for installing Odoo 18 on Linux systems.

## Available Linux Distros [Tested]

### Ubuntu Based

```bash
./odoo18-install-ubuntu.sh
```

#### Script Summary

This Bash script automates the installation of Odoo 18 on any Ubuntu-based distribution. It performs the following tasks:

1. **System Update:**
    - Updates the system repositories to ensure the latest packages are installed.

2. **Python 3.12 Installation:**
    - Checks if Python 3.12 is installed.
    - Installs it using deadsnakes PPA or compiles it from source if unavailable.

3. **Dependencies Installation:**
    - Installs required dependencies like PostgreSQL, Wkhtmltopdf, and various libraries for Odoo.

4. **PostgreSQL Setup:**
    - Starts and enables PostgreSQL.
    - Creates a PostgreSQL user named `odoo` if not already existing.

5. **User and Directory Setup:**
    - Creates a system user `odoo`.
    - Sets up necessary directories for Odoo, including `/opt/odoo/odoo-custom-addons`.

6. **Odoo Source Code:**
    - Clones the Odoo 18 repository from GitHub (if not already cloned).

7. **Virtual Environment:**
    - Creates a Python virtual environment for Odoo and installs Python dependencies.

8. **Configuration File:**
    - Creates an Odoo configuration file (`/etc/odoo.conf`).

9. **Odoo Service Setup:**
    - Configures Odoo as a systemd service to manage its startup and operation.

10. **Service Management:**
    - Reloads the systemd daemon, starts, and enables the Odoo service.

11. **Completion:**
    - Provides the URL to access Odoo and ensures all steps are complete.

The script includes error handling, checks for existing installations, and outputs color-coded messages for easier tracking of progress and errors.