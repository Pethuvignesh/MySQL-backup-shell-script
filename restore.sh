#!/bin/bash

# Set the variables
backup_directory="/backup/directory_path/"
hostname="hostname"
port="3306"
username="username"
password="password"

# Execute the myloader command
myloader --directory="$backup_directory" --verbose=3 --host="$hostname" --port="$port" --user="$username" --password="$password"
