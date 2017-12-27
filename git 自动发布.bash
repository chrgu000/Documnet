#!/bin/bash
 
PROJECT_NAME=project-name
DOMAIN=www.domain.com
HOME_ROOT="/home/htdocs/"
SOURCE_DIR=$HOME_ROOT"source"
PROJECT_DIR=$SOURCE_DIR"/"$PROJECT_NAME
WEB_ROOT=$HOME_ROOT""$DOMAIN"/"
TOMCAT_HOME="/usr/local/Tomcat-"$DOMAIN"/"
UPDATE_FILE_LOG=$HOME_ROOT"release/logs/"$PROJECT_NAME".log"
 
update_code(){
        if [ -d $PROJECT_DIR ]
        then
            cd $SOURCE_DIR
            git clone project_git_url
        else
            cd $PROJECT_DIR
            rm -f $UPDATE_FILE_LOG
            git pull >> $UPDATE_FILE_LOG
        fi
}
 
install(){
        cd $PROJECT_DIR
        /usr/local/apache-maven/bin/mvn clean 2>> $UPDATE_FILE_LOG
        /usr/local/apache-maven/bin/mvn -P release install 2>> $UPDATE_FILE_LOG
}
 
backup(){
        TIME=`date +"%Y-%m-%d-%H"`
        BACKUP_FILE=$HOME_ROOT"backup/"$PROJECT_NAME"_"$TIME".tar.gz"
        cd $HOME_ROOT
        tar -zcf $BACKUP_FILE $DOMAIN
}
 
deploy(){
        TEMP=$WEB_ROOT"*"
        rm -fR $TEMP
        TEMP=$TOMCAT_HOME"work/Catalina/"$DOMAIN
        sudo rm -fR $TEMP
        TEMP=$SOURCE_DIR"/"$PROJECT_NAME"/target/"$PROJECT_NAME"/*"
        sudo cp -fR $TEMP $WEB_ROOT
}
 
restart(){
        bash $TOMCAT_HOME"bin/catalina.sh" stop -force
        sleep 5
        bash $TOMCAT_HOME"bin/catalina.sh" start
}
 
help(){
        echo $"Usage: $0 {update_code|install|backup|deploy|restart}"
}
 
case "$1" in
	update_code)
			update_code
	;;
	install)
			install
	;;
	backup)
			backup
	;;
	deploy)
			deploy
	;;
	restart)
			restart
	;;
	-h)
			help
	;;
	--help)
			help
	;;
	*)
			update_code
			install
			backup
			deploy
			restart
	;;
 
esac
 
exit 0