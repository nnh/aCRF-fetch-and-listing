#!/bin/sh

# get_folder_path.sh
# Get the path to the folder. If the specified folder does not exist, create a new one.
# Created Date 2022.9.7
# Revision Date 2022.9.7

readonly g_html_extension=".html"

# Creates a folder in the specified path.
# $1 The path where the folder will be created.
# $2 Name of the folder to be created.
function create_folder(){
    local target_path="$1"
    local target_folder_name="$2"
    if [ ! -d "${target_path}${target_folder_name}" ]; then
        mkdir "${target_path}${target_folder_name}"
        if [ ! -d "${target_path}${target_folder_name}" ]; then
          echo "warn: mkdir command is mistake."
          exit 255
        fi
    fi
    g_temp_path="${target_path}${target_folder_name}/"
    return 0
}
# Main function of folder creation.
# $1 The trial name.
function get_folder_main(){
    # Create an output folder.
    readonly local output_parent='output'
    create_folder '../' ${output_parent}
    readonly output_parent_path=$g_temp_path
    # Create a temporary folder.
    readonly local temp_folder_name='temp'
    create_folder '../' ${temp_folder_name}
    readonly g_temp_folder_path=$g_temp_path
    # Create a folder for each Trial.
    local temp_trial_name=$1
    create_folder '../'${output_parent}'/' ${temp_trial_name}
    readonly g_trial_path=$g_temp_path
    return 0
}

get_folder_main $1