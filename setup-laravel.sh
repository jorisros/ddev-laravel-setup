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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version information (read from git tag)
SCRIPT_NAME="setup-laravel.sh"
REPO_OWNER="jorisros"
REPO_NAME="ddev-laravel-setup"
REPO_BRANCH="main"
RAW_GITHUB_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REPO_BRANCH"
SCRIPT_URL="$RAW_GITHUB_URL/$SCRIPT_NAME"
RELEASES_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# Get current version from git tag (if available)
get_current_version() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git describe --tags --abbrev=0 2>/dev/null || echo "dev"
    else
        echo "dev"
    fi
}

# Get latest version from GitHub API
get_latest_version() {
    local response=$(curl -fsSL "$RELEASES_URL" 2>/dev/null)
    
    # Check if the response contains "tag_name" (meaning it's a valid release)
    if echo "$response" | grep -q '"tag_name"'; then
        echo "$response" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\([^"]*\)".*/\1/'
    else
        echo ""
    fi
}

# Compare semantic versions
# Returns 0 if version1 < version2
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"
    
    if [ "$v1" = "$v2" ]; then
        return 1  # versions are equal
    fi
    
    if printf '%s\n%s' "$v1" "$v2" | sort -V | head -n 1 | grep -q "^$v1$"; then
        return 0  # v1 < v2
    fi
    
    return 1  # v1 >= v2
}

# Self-update function
self_update() {
    echo -e "${BLUE}Checking for updates...${NC}"
    
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    if [ -z "$latest_version" ]; then
        echo -e "${YELLOW}Could not determine latest version from GitHub${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Current version: $current_version${NC}"
    echo -e "${BLUE}Latest version:  $latest_version${NC}"
    
    if [ "$current_version" = "$latest_version" ]; then
        echo -e "${GREEN}You are already running the latest version ($latest_version)${NC}"
        return 0
    fi
    
    # Check if remote version is newer
    if compare_versions "$current_version" "$latest_version"; then
        echo -e "${YELLOW}New version available!${NC}"
        
        # Create temporary file
        local temp_file=$(mktemp)
        
        # Download latest version
        if ! curl -fsSL "$SCRIPT_URL" -o "$temp_file"; then
            echo -e "${RED}Error: Failed to download latest version${NC}"
            rm -f "$temp_file"
            return 1
        fi
        
        # Get the script path
        local script_path
        if [[ "$0" == /* ]]; then
            script_path="$0"
        else
            script_path="$(cd "$(dirname "$0")" && pwd)/$SCRIPT_NAME"
        fi
        
        # Ask user for confirmation
        read -p "Would you like to update now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup current script
            if ! cp "$script_path" "$script_path.bak"; then
                echo -e "${RED}Error: Failed to create backup${NC}"
                rm -f "$temp_file"
                return 1
            fi
            
            # Replace script with new version
            if ! cp "$temp_file" "$script_path"; then
                echo -e "${RED}Error: Failed to update script${NC}"
                # Restore backup
                mv "$script_path.bak" "$script_path"
                rm -f "$temp_file"
                return 1
            fi
            
            # Ensure script is executable
            chmod +x "$script_path"
            
            # Remove backup after successful update
            rm -f "$script_path.bak"
            
            echo -e "${GREEN}Script successfully updated to version $latest_version${NC}"
            echo -e "${YELLOW}Restarting with new version...${NC}"
            
            rm -f "$temp_file"
            
            # Re-execute the script with original arguments
            exec "$script_path" "$@"
        else
            echo -e "${YELLOW}Update skipped${NC}"
            rm -f "$temp_file"
            return 0
        fi
    else
        echo -e "${GREEN}You are running the latest version ($current_version)${NC}"
        return 0
    fi
}

# Check if user requested version or help
if [ "$1" = "--version" ]; then
    echo "ddev-laravel $(get_current_version)"
    exit 0
fi

if [ "$1" = "--update" ]; then
    self_update "$@"
    exit $?
fi

if [ "$1" = "--help" ]; then
    echo "Usage: $0 [OPTIONS] <project-name> [database-type]"
    echo ""
    echo "OPTIONS:"
    echo "  --version              Show version number"
    echo "  --update               Check for and install updates"
    echo "  --help                 Show this help message"
    echo ""
    echo "ARGUMENTS:"
    echo "  <project-name>         Name of the project to create"
    echo "  [database-type]        Database type: mysql (default), mariadb, sqlite, postgres"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 my-project"
    echo "  $0 my-project postgres"
    exit 0
fi

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
    echo ""
    echo "Run '$0 --help' for more information"
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
