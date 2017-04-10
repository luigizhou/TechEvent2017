#!/bin/bash

#set -x
#set -e
#set -n



### Variables

script=${0##*/}
log=${script}.$$.log
thishost=${HOSTNAME%%.*}
pkgs_list="epel-release python2-pip git ansible make rubygem-rake iproute vim-enhanced"
ecops_devops_box_playbook=box.yml

##
## Basic function
##

##
## Print a script utility recap
##
Header() {

  clear 
  cat <<-EOF | sed 's,  ,,g'

  This script is developed by the WCS E-Comm Operation team.

  It is a simple and stupid script that configure your box so that you can 
  try to reproduce this demo at your home.

  It performs an unattended installation of the following tools:

  - ansible
  - terraform
  - git
  - vim

  Execute the ${script} as super user.

  $ sudo -E ${script}


EOF

return 0
}

##
## Pretty logs function
##
Log() {
        message=$(echo ${1} | sed -e "s,(,\\\(,g" -e "s,),\\\),g")

        if [ "${silent}" = "" ]; then
                TEE=" | tee -a ${log}"
          else
                TEE=" >> ${log}"
        fi

        if [ -z "${message}" ]; then
                eval echo "\$(date '+%h %d %H:%M:%S') ${thishost} ${script}[$$]: no message provided" ${TEE}
          else
                eval echo "$(date '+%h %d %H:%M:%S') ${thishost} ${script}[$$]: ${message}" ${TEE}
        fi

        return 0
}

##
## Update basic OS and package meta-data
##
Update_OS() {

    Log "Update OS packages and package metadata"

    yum_rc=$(sudo yum update -y > /dev/null 2>&1 ; echo $? )
    if [[ $yum_rc -gt 0 ]] ; then
       Log "Yum update failed [err=003]"
       exit 3
    fi

    Log "Distro update complete"
    return 0
}

##
## Install required packages
##
Install_Req() {

    for pkg in ${pkgs_list} ; do
        rc=$( rpm -qa | grep -q ^${pkg} 2>&1 > /dev/null ; echo $? )
        if [[ $rc -gt 0 ]]; then
            yum_rc=$( sudo yum install -y $pkg 2>&1 > /dev/null ; echo $? )
            if [[ $yum_rc -gt 0 ]]; then
                Log "Package installation error [err=004]"
                exit 4
            fi
            Log "Package ${pkg} installation: SUCCESS!"
        else
            Log "Package ${pkg} already installed"
        fi
     done

    return 0
}



##
## Complete the box build using the ecops-box.yml playbook
##
Ansible_Run() {
   Log "Run the box.yml"
   ansible-playbook ${ecops_devops_box_playbook} -b -c local
}

### Main ###
Header
#Update_OS
Install_Req
Ansible_Run

exit 0
