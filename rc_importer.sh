#!/usr/bin/env bash

set -euo pipefail

# Constants
SCRIPT_NAME=$(basename "$0")
REQUIRED_COMMANDS=("wp" "unzip" "tar")
SUPPORTED_EXTENSIONS=(".zip" ".tar" ".tar.gz" ".tgz")

# Function to display usage information
usage() {
    echo "Usage: $SCRIPT_NAME <project> [new_domain]"
    echo "  <project>    : Name of the project archive file (without extension)"
    echo "  [new_domain] : Optional. New domain to set for the WordPress site"
    echo
    echo "Supported archive formats: ${SUPPORTED_EXTENSIONS[*]}"
    echo "If new_domain is not provided, the domain will not be changed."
}

# Function to check if required commands and zip file are available
check_requirements() {
    # Check if required commands are available
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' not found. Please install it and try again."
            exit 1
        fi
    done

    # Check if the project ZIP file exists
    local project="$1"
    if [[ ! -f "$project.zip" ]]; then
        echo "Error: The zip file '$project.zip' does not exist."
        exit 1
    fi
}

# Function to find the project archive file
find_archive_file() {
    local project="$1"
    for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
        if [[ -f "$project$ext" ]]; then
            echo "$project$ext"
            return 0
        fi
    done
    echo "Error: No supported archive file found for project '$project'."
    echo "Supported formats: ${SUPPORTED_EXTENSIONS[*]}"
    exit 1
}

# Function to extract project files
extract_files() {
    local archive_file="$1"

    echo "Backing up wp-config.php..."
    cp wp-config.php wp-config-local.php || { echo "Error: Failed to backup wp-config.php"; exit 1; }

    echo "Removing old files..."
    find . -maxdepth 1 ! -name '.' ! -name '..' ! -name 'wp-config-local.php' ! -name "$SCRIPT_NAME" ! -name "$(basename "$archive_file")" -exec rm -rf {} +

    echo "Extracting $archive_file..."
    case "$archive_file" in
        *.zip)
            unzip -q "$archive_file" || { echo "Error: Failed to unzip $archive_file"; exit 1; }
            ;;
        *.tar)
            tar -xf "$archive_file" || { echo "Error: Failed to extract $archive_file"; exit 1; }
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$archive_file" || { echo "Error: Failed to extract $archive_file"; exit 1; }
            ;;
        *)
            echo "Error: Unsupported archive format for $archive_file"
            exit 1
            ;;
    esac

    # Check if extracted content is inside a single directory
    local extracted_dirs=(*/)
    if [ ${#extracted_dirs[@]} -eq 1 ]; then
        local main_dir="${extracted_dirs[0]}"
        echo "Extracted content is inside '$main_dir'. Moving files to current directory..."
        mv "$main_dir"* "$main_dir".[!.]* . 2>/dev/null || true
        rmdir "$main_dir"
    fi
}

# Function to update WordPress configuration
update_wp_config() {
    local config_file="wp-config-local.php"

    local db_params=("DB_NAME" "DB_USER" "DB_PASSWORD")
    for param in "${db_params[@]}"; do
        local value=$(grep "$param" "$config_file" | cut -d \' -f 4)
        wp config set "$param" "$value" || { echo "Error: Failed to set $param"; exit 1; }
    done
}

# Function to import database
import_database() {
    echo "Resetting database..."
    wp db reset --yes || { echo "Error: Failed to reset database"; exit 1; }

    echo "Importing database..."
    local database_file=$(ls *.sql 2>/dev/null | sort -V | tail -n1)
    if [[ -z "$database_file" ]]; then
        echo "Error: No SQL file found for import."
        exit 1
    fi
    wp db import "$database_file" --allow-root || { echo "Error: Failed to import database"; exit 1; }
}

# Function to change domain
change_domain() {
    local new_domain="$1"
    if [[ -z "$new_domain" ]]; then
        echo "New domain not provided. Skipping domain change."
        return
    fi

    echo "Changing domain..."
    local original_domain=$(wp option get siteurl)
    echo "Replacing '$original_domain' with 'https://$new_domain'"
    wp search-replace "$original_domain" "https://$new_domain" --all-tables --report-changed-only || { echo "Error: Failed to change domain"; exit 1; }
    wp cache flush || { echo "Error: Failed to flush cache"; exit 1; }
}

# Function to clean up temporary files
clean_up() {
    echo "Cleaning up..."
    local archive_file="$1"

    local files_to_remove=("wp-config-local.php" "*.sql" "table.prefix" "migrate_into_rc.sh")
    for file in "${files_to_remove[@]}"; do
        rm -f "$file"
    done

    # Ask about removing the archive file
    read -p "Do you want to remove the archive file ($archive_file)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$archive_file"
        echo "Archive file removed."
    else
        echo "Archive file kept."
    fi
}

# Main function
main() {
    local project="$1"
    local new_domain="${2:-}"

    check_requirements "$project"
    local archive_file=$(find_archive_file "$project")
    extract_files "$archive_file"
    update_wp_config
    import_database
    change_domain "$new_domain"

    echo
    echo "***************************************"
    echo "*******   Migration completed   *******"
    echo "***************************************"
    echo

    # Ask if files should be cleaned
    read -p "Do you want to clean up the files? (y/Y to proceed) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_up "$archive_file"
    else
        echo "Cleanup skipped."
    fi
}

# Check if at least one argument is provided
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

# Run the main function
main "$@"