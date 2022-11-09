#!/bin/sh

# get_acrf.sh
# Download all aCRF with the specified trial name. Depends on get_folder_path.sh.
# Created Date 2022.9.7
# Revision Date 2022.11.9

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
    readonly local base_url=$(cat ../input_base_url)
    if [[ ! ${base_url} =~ ^https.*$ ]]; then
          echo "No mention of input base url."
          exit 255
    fi
    readonly local output_base_url=$(cat ../output_base_url)
    if [[ ! ${output_base_url} =~ ^https.*$ ]]; then
          echo "No mention of output base url."
          exit 255
    fi
    readonly local trial_name="$2"
    source ./get_folder_path.sh ${trial_name} 
    readonly local id="$1"
    read -p 'Password: ' password
    readonly local signin_url="${base_url}/users/sign_in"
    readonly local csrf_token=$(curl -sS -L -c ${g_temp_folder_path}login.cookie1 "${signin_url}" | grep csrf-token | sed -e  's/.*content\=\"//g'  | sed -e 's/\" \/.*//g')
    curl -sS -L -F "user[email]=${id}" -F "user[password]=${password}" -F "authenticity_token=${csrf_token}" -b ${g_temp_folder_path}login.cookie1 -c ${g_temp_folder_path}login.cookie2 "${signin_url}" -o ${g_temp_folder_path}test1.html
    readonly local trial_url="${base_url}trials/${trial_name}/sheets"
    readonly local aws_dir_name=$(echo ${trial_name} | tr '[:upper:]' '[:lower:]')
    readonly local index_html=${g_trial_path}index.html
    echo '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=SHIFT_JIS">' > ${index_html}
    echo '<style>' >> ${index_html}
    echo 'body {font-family: sans-serif;}' >> ${index_html}
    echo 'ol {background-color:#ffffff;border-bottom:solid 1px #cccccc;}' >> ${index_html}
    echo 'li {border-top:solid 1px #cccccc;padding:10px 20px;}' >> ${index_html}
    echo 'a {font-size:16px;color:#000000;text-decoration: none;}' >> ${index_html}
    echo '</style>' >> ${index_html}
    echo '<ol>' >> ${index_html}
    curl -sS -b ${g_temp_folder_path}login.cookie2 ${trial_url} | grep '<a href=.*edit"' | sed -e "s|/trials/${trial_name}/sheets/|${output_base_url}${aws_dir_name}/|g" -e 's|/edit|.html|' -e 's|$|</li>|g' -e 's|<a href=|<li><a href=|g' >> ${index_html}
    echo '</ol>' >> ${index_html}
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
        sed -e "s|/trials/${trial_name}/sheets|\.|" -e 's|<a href="/">ホーム</a>|ホーム|' -e 's|<a id="sign_out" rel="nofollow" data-method="delete" href="/users/sign_out">ログアウト</a>|ログアウト|' -e 's|<a target="_blank" id="help" href="/welcome/help">ヘルプ</a>|ヘルプ|' -e 's|<a href="mailto:.*%0D%0A||' -e 's|施設:.*%0D%0A||' -e 's|URL:.*%0D%0A||' -e 's|以下に問い合わせ内容を記載して送信してください。%0D%0A||' -e 's|%0D%0A||' -e 's|">データセンターに連絡</a>|データセンターに連絡|' -e 's|.*名古屋医療センター.*||' ${g_trial_path}${output_html_name} > ${g_temp_folder_path}temp.html
        mv ${g_temp_folder_path}temp.html ${g_trial_path}${output_html_name}
    done 
    # Upload files.
    readonly local parent_bucket_name=$(echo ${output_base_url} | sed -e 's|https://||' -e 's/\..*//')
    readonly local upload_s3_url=s3://${parent_bucket_name}/
    readonly local folder_existence_check=$(aws s3 ls ${upload_s3_url}| grep ${aws_dir_name})
    if [ -z "$folder_existence_check" ]; then
        aws s3 mb ${upload_s3_url}${aws_dir_name}
    fi
    aws s3 cp ${g_trial_path} ${upload_s3_url}${aws_dir_name} --recursive
    exit 0
}
main $1 $2
