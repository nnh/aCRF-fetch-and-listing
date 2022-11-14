#!/bin/sh

# get_acrf.sh
# Download all aCRF with the specified trial name. Depends on get_folder_path.sh.
# Created Date 2022.9.7
# Revision Date 2022.11.11

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
# Create index.html.
function create_index(){
    create_index_css
    echo '<ol>' >> ${index_html}
    curl -sS -b ${g_temp_folder_path}login.cookie2 ${trial_url} | grep '<a href=.*edit"' | sed -e "s|/trials/${trial_name}/sheets/|${output_base_url}${aws_dir_name}/|g" -e 's|/edit|.html|' -e 's|$|</li>|g' -e 's|<a href=|<li><a href=|g' >> ${index_html}
    echo '</ol>' >> ${index_html}
}
# Sign in to the URL listed in the base_url file and download the aCRF information for the trial name specified in the argument.
# $1 The sign-in ID in single quotes.
# $2 The sign-in Password in single quotes.
# $3 The trial name in single quotes.
function main(){
    readonly id="$1"
    readonly trial_name="$2"
    source ./common.sh
    init
    read -p 'Password: ' password
    readonly local trial_url="${base_url}trials/${trial_name}/sheets"
    login
    readonly local index_html=${g_trial_path}acrf_index.html
    create_index
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
        # Rewrite CSS references to relative paths. Remove unnecessary a tag.
        sed -e "s|/trials/${trial_name}/sheets|\.|" -e 's|<a href="/">ホーム</a>|ホーム|' -e 's|<a id="sign_out" rel="nofollow" data-method="delete" href="/users/sign_out">ログアウト</a>|ログアウト|' -e 's|<a target="_blank" id="help" href="/welcome/help">ヘルプ</a>|ヘルプ|' -e 's|<a href="mailto:.*%0D%0A||' -e 's|施設:.*%0D%0A||' -e 's|URL:.*%0D%0A||' -e 's|以下に問い合わせ内容を記載して送信してください。%0D%0A||' -e 's|%0D%0A||' -e 's|">データセンターに連絡</a>|データセンターに連絡|' -e 's|.*名古屋医療センター - データセンター.*||' ${g_trial_path}${output_html_name} > ${g_temp_folder_path}temp.html
        mv ${g_temp_folder_path}temp.html ${g_trial_path}${output_html_name}
    done 
    upload_files
    exit 0
}
main $1 $2
