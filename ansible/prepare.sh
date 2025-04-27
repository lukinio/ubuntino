#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status


PYTHON_VERSION="3.13.1"
PYTHON="${HOME}/.pyenv/versions/${PYTHON_VERSION}/bin/python"
PYENV="${HOME}/.pyenv/bin/pyenv"
VENV_DIR="${HOME}/ansible_venv"
REQUIREMENTS_FILE="requirements.txt"
DEPENDENCIES_FILE="dependencies.txt"


# Read dependencies from file into an array
if [[ -f "$DEPENDENCIES_FILE" ]]; then
   mapfile -t DEPENDENCIES < "$DEPENDENCIES_FILE"
else
   echo "Dependencies file $DEPENDENCIES_FILE not found!"
   exit 1
fi

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update -y
sudo apt install -y "${DEPENDENCIES[@]}"

# Install PyEnv
echo "Installing PyEnv..."
if ! command -v pyenv >/dev/null 2>&1; then
   rm -rf ~/.pyenv/
   curl https://pyenv.run | bash
else
    echo "PyEnv is already installed."
fi

# Configure shell
if ! grep -q 'PyEnv configuration' ~/.bashrc; then
   echo "Configuring shell for PyEnv..."
   cat >>~/.bashrc <<'EOF'

# PyEnv configuration
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
EOF
fi


# Install python
echo "Python installation: ${PYTHON}"
${PYENV} install -s "${PYTHON_VERSION}"

# Verify Python 3.13 installation
echo "Verifying ${PYTHON} installation..."
${PYTHON} --version || { echo "Python ${PYTHON_VERSION} installation failed"; exit 1; }

# Create a virtual environment
echo "Creating virtual environment in ${VENV_DIR} using Python ${PYTHON_VERSION}"
rm -rf "${VENV_DIR}"
${PYTHON} -m venv ${VENV_DIR}

# Activate the virtual environment
source "${VENV_DIR}/bin/activate"

# Bootstrap and upgrade pip
echo "Bootstrapping and upgrading pip..."
${PYTHON} -m ensurepip --upgrade
${PYTHON} -m pip install --upgrade pip

# Ensure requirements.txt exists
echo "Checking for requirements.txt..."
if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
   echo "requirements.txt does not exist"
   exit 1
fi

# Install Python packages from requirements.txt
echo "Installing Python packages from ${REQUIREMENTS_FILE}"
pip install -r ${REQUIREMENTS_FILE}

# Step 8: Verify Ansible installation
echo "Verifying Ansible installation..."
ansible_version=$(ansible --version | head -n 1)
echo "Ansible version $ansible_version has been successfully installed in the virtual environment."

# Step 9: Provide instructions to the user
cat <<EOF

Installation Complete!

To use Ansible:
1. Reload shell:
   source ~/.bashrc

2. Activate the virtual environment:
   source ${VENV_DIR}/bin/activate

3. Run Ansible commands as needed.

4. When done, deactivate the environment with:
   deactivate

EOF
