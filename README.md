# RC Importer

`rc_importer.sh` is a Bash script designed to automate the process of importing and setting up a WordPress project from an archive file, specifically tailored for RunCloud servers. It handles tasks such as extracting the project files, updating the WordPress configuration, importing the database, and optionally changing the domain. While it is optimized for RunCloud servers, it should work with other types of servers as well.

## Features

-   Extracts project files from supported archive formats (.zip, .tar, .tar.gz, .tgz).
-   Backs up the existing `wp-config.php` file and updates the WordPress configuration with database parameters.
-   Imports the database from the latest `.sql` file in the directory.
-   Optionally changes the domain of the WordPress site.
-   Cleans up temporary files after the import process.

## Requirements

The script requires the following commands to be available on your system:

-   `wp` (WP-CLI)
-   `unzip`
-   `tar`

## Usage

```bash
./rc_importer.sh <project> [new_domain]
```

-   `<project>`: Name of the project archive file (without extension).
-   `[new_domain]`: Optional. New domain to set for the WordPress site.

## Example

This command will:

1. Check if the required commands are available.
2. Find and extract the project archive file (`my_project.zip`, `my_project.tar`, etc.).
3. Back up the existing `wp-config.php` file and update it with database parameters from `wp-config-local.php`.
4. Import the database from the latest `.sql` file in the directory.
5. Change the domain of the WordPress site to `https://example.com`.
6. Clean up temporary files and optionally remove the archive file.

## Script Details

### Constants

-   `SCRIPT_NAME`: The name of the script.
-   `REQUIRED_COMMANDS`: List of required commands.
-   `SUPPORTED_EXTENSIONS`: List of supported archive file extensions.

### Functions

-   `usage()`: Displays usage information.
-   `check_requirements()`: Checks if required commands are available.
-   `find_archive_file(project)`: Finds the project archive file.
-   `extract_files(archive_file)`: Extracts project files from the archive.
-   `update_wp_config()`: Updates the WordPress configuration with database parameters.
-   `import_database()`: Imports the database from the latest `.sql` file.
-   `change_domain(new_domain)`: Changes the domain of the WordPress site.
-   `clean_up(archive_file)`: Cleans up temporary files and optionally removes the archive file.
-   `main(project, new_domain)`: Main function that orchestrates the import process.

### Error Handling

The script uses `set -euo pipefail` to ensure that it exits immediately if a command exits with a non-zero status, if an undefined variable is used, or if any command in a pipeline fails.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## Contact

For any questions or support, please open an issue in the GitHub repository.
