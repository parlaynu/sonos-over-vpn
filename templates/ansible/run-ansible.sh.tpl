#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "$${BASH_SOURCE[0]}" )" && pwd )"
RUN_DIR="$( dirname $( dirname $${SCRIPT_DIR} ) )"
cd $${RUN_DIR}

export ANSIBLE_HOST_KEY_CHECKING=0
export ANSIBLE_SSH_ARGS="-F local/ssh.cfg -C -o ControlMaster=auto -o ControlPersist=60s"

ansible-playbook \
        --inventory=$${SCRIPT_DIR}/${inventory_file} \
        $${SCRIPT_DIR}/playbook.yml

