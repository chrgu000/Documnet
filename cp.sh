#/bin/bash
mkdir /tmp/$1
find $1 \( ! -name *.jar ! -name *.properties \) | cpio -admvp /tmp/mbm/
chown ibd:ibd /tmp/$1

