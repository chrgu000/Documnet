#!/bin/bash


#add system user
add_sys () {
        id $1 &> /dev/null
        if      [[ $? -ne 0 ]]
        then    useradd -r -s /sbin/nologin -M $1
        fi
}
#add general user
add_user () {
        id $1 &> /dev/null
        if      [[ $? -ne 0 ]]
        then    useradd -r -s /sbin/nologin -M $1
        useradd $1
        fi
}
case "$1" in
        system)
        name=$2
        add_sys $name
        ;;
        user)
        add_user $name
        ;;
        *)
        echo "Usage $0 {system|user} USER_NAME"
        ;;
esac