#!/bin/sh

# common.sh
# Common Functions.
# Created Date 2022.11.11
# Revision Date 2022.11.11
readonly g_html_extension=".html"
# Get the URL of the input/output target from a text file.
function get_base_url(){
    readonly base_url=$(cat ../input_base_url)
    if [[ ! ${base_url} =~ ^https.*$ ]]; then
          echo "No mention of input base url."
          exit 255
    fi
    readonly output_base_url=$(cat ../output_base_url)
    if [[ ! ${output_base_url} =~ ^https.*$ ]]; then
          echo "No mention of output base url."
          exit 255
    fi
    return 0
}
# Creates a folder in the specified path.
# $1 The path where the folder will be created.
# $2 Name of the folder to be created.
function create_folder(){
    target_path="$1"
    target_folder_name="$2"
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
    readonly output_parent='output'
    create_folder '../' ${output_parent}
    readonly output_parent_path=$g_temp_path
    # Create a temporary folder.
    readonly temp_folder_name='temp'
    create_folder '../' ${temp_folder_name}
    readonly g_temp_folder_path=$g_temp_path
    # Create a folder for each Trial.
    temp_trial_name=$1
    create_folder '../'${output_parent}'/' ${temp_trial_name}
    readonly g_trial_path=$g_temp_path
    return 0
}
function login(){
    readonly signin_url="${base_url}/users/sign_in"
    readonly csrf_token=$(curl -sS -L -c ${g_temp_folder_path}login.cookie1 "${signin_url}" | grep csrf-token | sed -e  's/.*content\=\"//g'  | sed -e 's/\" \/.*//g')
    curl -sS -L -F "user[email]=${id}" -F "user[password]=${password}" -F "authenticity_token=${csrf_token}" -b ${g_temp_folder_path}login.cookie1 -c ${g_temp_folder_path}login.cookie2 "${signin_url}" -o ${g_temp_folder_path}test1.html
}
function init(){
    get_base_url
    if [[ $? -ne 0 ]]; then
        echo "error: get_base_url"
        exit 255
    fi
    get_folder_main ${trial_name}
    if [[ $? -ne 0 ]]; then
        echo "error: get_folder_main"
        exit 255
    fi
    readonly aws_dir_name=$(echo ${trial_name} | tr '[:upper:]' '[:lower:]')
    return 0
}
# Output css of index.html.
function create_index_css(){
    echo '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=SHIFT_JIS">' > ${index_html}
    echo '<style>' >> ${index_html}
    echo 'body {font-family: sans-serif;}' >> ${index_html}
    echo 'ol {background-color:#ffffff;border-bottom:solid 1px #cccccc;}' >> ${index_html}
    echo 'li {border-top:solid 1px #cccccc;padding:10px 20px;}' >> ${index_html}
    echo 'a {font-size:16px;color:#000000;text-decoration: none;}' >> ${index_html}
    echo '</style>' >> ${index_html}
}
# Upload the file to the URL listed in ../output_base_url. 
function upload_files(){
    readonly local parent_bucket_name=$(echo ${output_base_url} | sed -e 's|https://||' -e 's/\..*//')
    readonly local upload_s3_url=s3://${parent_bucket_name}/
    readonly local folder_existence_check=$(aws s3 ls ${upload_s3_url}| grep ${aws_dir_name})
    if [ -z "$folder_existence_check" ]; then
        aws s3 mb ${upload_s3_url}${aws_dir_name}
    fi
    aws s3 cp ${g_trial_path} ${upload_s3_url}${aws_dir_name} --recursive
}