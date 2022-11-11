#!/bin/sh

# get_define_xml.sh
# Download define.xml with the specified trial name. Depends on common.sh.
# Created Date 2022.11.11
# Revision Date 2022.11.11

# Create index.html.
function create_index(){
    create_index_css
    echo '<ol>' >> ${index_html}
    echo '<a href="'${define_xml_url}'">'${trial_name} Define-XML'</a>'>> ${index_html}
    echo '</ol>' >> ${index_html}
}
# Sign in to the URL listed in the base_url file and download the define.xml for the trial name specified in the argument.
# $1 The sign-in ID in single quotes.
# $2 The sign-in Password in single quotes.
# $3 The trial name in single quotes.
function main(){
    readonly local xsl_name="define2-0-0.xsl"
    readonly xml_name="define.xml"
    readonly id="$1"
    readonly trial_name="$2"
    source ./common.sh
    init
    read -p 'Password: ' password
    readonly trial_url="${base_url}trials/${trial_name}/cdisc/domain_configs/"
    login
    readonly index_html=${g_trial_path}xml_index.html
    readonly define_xml_url=${output_base_url}${aws_dir_name}/${xml_name}
    create_index
    curl -sS -b ${g_temp_folder_path}login.cookie2 "${trial_url}${xml_name}" | sed -e "s|/${xsl_name}|${xsl_name}|g" > ${g_trial_path}${xml_name}
    curl -sS -b ${g_temp_folder_path}login.cookie2 "${base_url}${xsl_name}"  -o ${g_trial_path}${xsl_name}
    upload_files
    exit 0
}
main $1 $2