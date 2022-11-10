#!/bin/sh

# test20221110.sh
# 
# Created Date 2022.11.10

# Revision Date 2022.x.x
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
    readonly local trial_url="${base_url}trials/${trial_name}/cdisc/domain_configs/"
    #readonly local aws_dir_name=$(echo ${trial_name} | tr '[:upper:]' '[:lower:]')
    #readonly local index_html=${g_trial_path}index.html
    #echo '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=SHIFT_JIS">' > ${index_html}
    #echo '<style>' >> ${index_html}
    #echo 'body {font-family: sans-serif;}' >> ${index_html}
    #echo 'ol {background-color:#ffffff;border-bottom:solid 1px #cccccc;}' >> ${index_html}
    #echo 'li {border-top:solid 1px #cccccc;padding:10px 20px;}' >> ${index_html}
    #echo 'a {font-size:16px;color:#000000;text-decoration: none;}' >> ${index_html}
    #echo '</style>' >> ${index_html}
    #echo '<ol>' >> ${index_html}
    #curl -sS -b ${g_temp_folder_path}login.cookie2 ${trial_url} | grep '<a href=.*edit"' | sed -e "s|/trials/${trial_name}/sheets/|${output_base_url}${aws_dir_name}/|g" -e 's|/edit|.html|' -e 's|$|</li>|g' -e 's|<a href=|<li><a href=|g' >> ${index_html}
    #echo '</ol>' >> ${index_html}
    #readonly local aCrf_head='<a href\="'
    #readonly local aCrf_foot='">aCRF<\/a>'
    readonly local xsl_name="define2-0-0.xsl"
    curl -sS -b ${g_temp_folder_path}login.cookie2 "${trial_url}define.xml" | sed -e 's|/define2-0-0.xsl|define2-0-0.xsl|g' >> ${g_temp_folder_path}define.xml
    curl -sS -b ${g_temp_folder_path}login.cookie2 "${base_url}${xsl_name}"  -o ${g_temp_folder_path}${xsl_name}
}
main $1 $2 $3