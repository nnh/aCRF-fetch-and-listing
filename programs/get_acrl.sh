#!/bin/sh

# get_acrf.sh
# Download all aCRF with the specified trial name. Depends on get_folder_path.sh.
# Created Date 2022.9.7
# Revision Date 2022.9.7

# Download the CSS files.
# $1 Name of HTML file.
function get_css(){
    # output folder
    local target_html_name=$1
    local target_url_str="/trials/${trial_name}/sheets/"
    local css_folder_name=$(echo ${target_html_name} | sed -e "s/${g_html_extension}//")
    create_folder ${g_trial_path} ${css_folder_name}
    local css_folder_path=${g_trial_path}${css_folder_name}/
    # Get style sheets.
    local stylesheet_head='<link rel="stylesheet"' 
    local css_url_list=$(grep "${target_url_str}" ${g_trial_path}${target_html_name} | sed -e "s|${stylesheet_head}.*href\=\"/||g" | sed -e "s|\" \/>||")
    for i in ${css_url_list[@]}
    do
        local temp_css_url=$i
        local file_name=$(basename ${temp_css_url})
        curl -sS -b ${g_temp_folder_path}login.cookie2 ${base_url}$i > ${css_folder_path}${file_name}
    done
    return 0
}
# Sign in to the URL listed in the base_url file and download the aCRF information for the trial name specified in the argument.
# $1 The sign-in ID in single quotes.
# $2 The sign-in Password in single quotes.
# $3 The trial name in single quotes.
function main(){
    readonly local base_url=$(cat ../base_url)
    if [[ ! ${base_url} =~ ^https.*$ ]]; then
          echo "No mention of base url."
          exit 255
    fi
    readonly local trial_name="$2"
    source ./get_folder_path.sh ${trial_name} 
    readonly local id="$1"
    read -p 'Password: ' password
    readonly local signin_url="${base_url}/users/sign_in"
    readonly local csrf_token=$(curl -sS -L -c ${g_temp_folder_path}login.cookie1 "${signin_url}" | grep csrf-token | sed -e  's/.*content\=\"//g'  | sed -e 's/\" \/.*//g')
    curl -sS -L -F "user[email]=${id}" -F "user[password]=${password}" -F "authenticity_token=${csrf_token}" -b ${g_temp_folder_path}login.cookie1 -c ${g_temp_folder_path}login.cookie2 "${signin_url}" -o ${g_temp_folder_path}test1.html
    readonly local trial_url="${base_url}/trials/${trial_name}/sheets"
    readonly local aCrf_head='<a href\="'
    readonly local aCrf_foot='">aCRF<\/a>'
    readonly local target_html_list=$(curl -sS -b ${g_temp_folder_path}login.cookie2 "${trial_url}" | grep "${aCrf_head}.*${aCrf_foot}" | sed -e "s|${aCrf_head}|${base_url}|g" | sed -e "s/${aCrf_foot}//g")
    readonly local replace_str="${base_url}/trials/${trial_name}/cdisc/sheet/"
    for i in ${target_html_list[@]}
    do
        local target_html=$i
        local target_sheet_name=$(echo ${target_html} | sed -e "s|${replace_str}||" | sed -e "s|/annotations||")
        local output_html_name=${target_sheet_name}${g_html_extension}
        curl -sS -b ${g_temp_folder_path}login.cookie2 ${target_html} > ${g_trial_path}${output_html_name}
        get_css ${output_html_name}
        # Rewrite CSS references to relative paths.
        sed -e "s|/trials/${trial_name}/sheets|\.|" ${g_trial_path}${output_html_name} > ${g_temp_folder_path}temp.html
        mv ${g_temp_folder_path}temp.html ${g_trial_path}${output_html_name}
    done 
    exit 0
}
main $1 $2
