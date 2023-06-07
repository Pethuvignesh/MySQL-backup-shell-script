#!/bin/bash

# Set text color variables
green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m' # Reset color

# Set the database hostname, username, and password
db_host="hostname"
db_user="user_name"
db_password="password"

# Set the folder name based on the current date
date=$(date +"%Y%m%d")
folder_name="backup_$date"

# Set the path where the folder will be created
folder_path="/home/ubuntu/db_backups/$folder_name"

# Set the path where the zip file will be created
zip_path="/home/ubuntu/db_backups/$folder_name.zip"

# Set the S3 bucket name and path
s3_bucket="bucket_name"
s3_path="bucket_path"

# Create the folder
mkdir "$folder_path"

# Check if the folder was created successfully
if [ $? -eq 0 ]; then
    echo -e "${green}Folder '$folder_name' created successfully.${reset}"

    # Set permissions to 755
    chmod 755 "$folder_path"
    echo -e "${green}Permissions set to 755 for folder '$folder_name'.${reset}"

    # Install mydumper
    sudo apt-get update
    sudo apt-get install -y build-essential cmake zlib1g-dev libglib2.0-dev libmysqlclient-dev libpcre3-dev libssl-dev

    # Clone the mydumper repository
    git clone https://github.com/maxbube/mydumper.git
    cd mydumper

    # Build mydumper
    cmake .
    make
    sudo make install

    # Verify mydumper installation
    mydumper --version

    # Install zip
    sudo apt-get install -y zip

    # Dump all databases into the created folder
    mydumper --host="$db_host" --user="$db_user" --password="$db_password" --outputdir="$folder_path"

    # Check if the database dump was successful
    if [ $? -eq 0 ]; then
        echo -e "${green}All databases dumped successfully.${reset}"

        # Compress the folder into a zip file
        zip -r "$zip_path" "$folder_path"
        if [ $? -eq 0 ]; then
            echo -e "${green}Folder '$folder_name' compressed into '$folder_name.zip' successfully.${reset}"

            # Upload the zip file to S3
            aws s3 cp "$zip_path" "s3://$s3_bucket/$s3_path/"
            if [ $? -eq 0 ]; then
                echo -e "${green}Zip file uploaded to S3 successfully.${reset}"
            else
                echo -e "${red}Failed to upload zip file to S3.${reset}"
            fi
        else
            echo -e "${red}Failed to compress folder '$folder_name' into a zip file.${reset}"
        fi
    else
        echo -e "${red}Failed to dump all databases.${reset}"
    fi

else
    echo -e "${red}Failed to create folder '$folder_name'.${reset}"
fi
