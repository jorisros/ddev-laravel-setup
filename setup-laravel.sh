#!/bin/bash

# Laravel DDEV Setup Script
# Creates a new Laravel 12 project with DDEV
# Usage: ./setup-laravel.sh <project-name> [database-type]
# Database types: mysql (default), mariadb, sqlite, postgres

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ddev is installed
if ! command -v ddev &> /dev/null; then
    echo -e "${RED}Error: ddev is not installed or not in PATH${NC}"
    echo "Please install ddev from: https://ddev.readthedocs.io/en/stable/users/install/"
    exit 1
fi

# Check if project name argument is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Project name is required${NC}"
    echo "Usage: $0 <project-name> [database-type]"
    echo "Database types: mysql (default), mariadb, sqlite, postgres"
    exit 1
fi

PROJECT_NAME="$1"
DB_TYPE="${2:-mysql}"  # Default to mysql if not specified

# Validate database type
case "$DB_TYPE" in
    mysql|mariadb|sqlite|postgres)
        echo -e "${GREEN}Using database type: $DB_TYPE${NC}"
        ;;
    *)
        echo -e "${RED}Error: Invalid database type '$DB_TYPE'${NC}"
        echo "Supported types: mysql (default), mariadb, sqlite, postgres"
        exit 1
        ;;
esac

# Check if project already exists in DDEV
if ddev list | grep -q "$PROJECT_NAME"; then
    echo -e "${RED}Error: DDEV project '$PROJECT_NAME' already exists${NC}"
    echo "Please remove it first with: ddev remove $PROJECT_NAME --remove-data"
    exit 1
fi

# Check if directory already exists
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Directory '$PROJECT_NAME' already exists${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating project directory: $PROJECT_NAME${NC}"
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo -e "${YELLOW}Configuring DDEV for Laravel with $DB_TYPE...${NC}"
case "$DB_TYPE" in
    mysql)
        ddev config --project-type=laravel --database=mysql:8.0 --docroot=public --disable-upload-dirs-warning
        ;;
    mariadb)
        ddev config --project-type=laravel --database=mariadb:10.11 --docroot=public --disable-upload-dirs-warning
        ;;
    postgres)
        ddev config --project-type=laravel --database=postgres:15 --docroot=public --disable-upload-dirs-warning
        ;;
    sqlite)
        ddev config --project-type=laravel --docroot=public --disable-upload-dirs-warning
        ;;
esac

echo -e "${YELLOW}Starting DDEV...${NC}"
ddev start

echo -e "${YELLOW}Creating Laravel project...${NC}"
ddev composer create-project "laravel/laravel:^12"

echo -e "${YELLOW}Configuring Laravel database connection...${NC}"
# Update .env file based on database type
if [ -f ".env" ]; then
    case "$DB_TYPE" in
        mysql|mariadb)
            sed -i.bak 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env
            sed -i.bak 's/DB_HOST=.*/DB_HOST=db/' .env
            sed -i.bak 's/DB_PORT=.*/DB_PORT=3306/' .env
            sed -i.bak 's/DB_DATABASE=.*/DB_DATABASE=db/' .env
            sed -i.bak 's/DB_USERNAME=.*/DB_USERNAME=db/' .env
            sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=db/' .env
            echo -e "${GREEN}Database configuration updated for $DB_TYPE${NC}"
            ;;
        postgres)
            sed -i.bak 's/DB_CONNECTION=.*/DB_CONNECTION=pgsql/' .env
            sed -i.bak 's/DB_HOST=.*/DB_HOST=db/' .env
            sed -i.bak 's/DB_PORT=.*/DB_PORT=5432/' .env
            sed -i.bak 's/DB_DATABASE=.*/DB_DATABASE=db/' .env
            sed -i.bak 's/DB_USERNAME=.*/DB_USERNAME=db/' .env
            sed -i.bak 's/DB_PASSWORD=.*/DB_PASSWORD=db/' .env
            echo -e "${GREEN}Database configuration updated for PostgreSQL${NC}"
            ;;
        sqlite)
            sed -i.bak 's/DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env
            sed -i.bak 's/DB_DATABASE=.*/DB_DATABASE=\/var\/www\/html\/database\/database.sqlite/' .env
            echo -e "${GREEN}Database configuration updated for SQLite${NC}"
            ;;
    esac
    rm -f .env.bak
fi

echo -e "${YELLOW}Launching site in browser...${NC}"
ddev launch

echo -e "${GREEN}Setup complete! Your Laravel project is ready with $DB_TYPE database.${NC}"
