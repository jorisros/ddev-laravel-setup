#!/bin/bash

# Laravel DDEV Setup Script
# Creates a new Laravel 12 project with DDEV
# Usage: ./setup-laravel.sh <project-name>

set -e  # Exit on error

# Check if ddev is installed
if ! command -v ddev &> /dev/null; then
    echo "Error: ddev is not installed or not in PATH"
    echo "Please install ddev from: https://ddev.readthedocs.io/en/stable/users/install/"
    exit 1
fi

# Check if project name argument is provided
if [ -z "$1" ]; then
    echo "Error: Project name is required"
    echo "Usage: $0 <project-name>"
    exit 1
fi

PROJECT_NAME="$1"

# Check if project already exists in DDEV
if ddev list | grep -q "$PROJECT_NAME"; then
    echo "Error: DDEV project '$PROJECT_NAME' already exists"
    echo "Please remove it first with: ddev remove $PROJECT_NAME --remove-data"
    exit 1
fi

# Check if directory already exists
if [ -d "$PROJECT_NAME" ]; then
    echo "Error: Directory '$PROJECT_NAME' already exists"
    exit 1
fi

echo "Creating project directory: $PROJECT_NAME"
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "Configuring DDEV for Laravel..."
ddev config --project-type=laravel --database=mysql:8.0 --docroot=public --disable-upload-dirs-warning

echo "Configuring Laravel database connection..."
# Update .env file to use MySQL
if [ -f ".env" ]; then
    sed -i.bak 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
    sed -i.bak 's/DB_HOST=.*/DB_HOST=db/' .env
    sed -i.bak 's/DB_PORT=.*/DB_PORT=3306/' .env
    sed -i.bak 's/DB_DATABASE=.*/DB_DATABASE=db/' .env
    sed -i.bak 's/DB_USERNAME=.*/DB_USERNAME=db/' .env
    sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=db/' .env
    rm .env.bak
    echo "Database configuration updated in .env"
fi

echo "Starting DDEV..."
ddev start

echo "Creating Laravel project..."
ddev composer create-project "laravel/laravel:^12"

echo "Launching site in browser..."
ddev launch

echo "Setup complete!"
