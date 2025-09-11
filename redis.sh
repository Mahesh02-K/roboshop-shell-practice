#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOG_FILE

#check root priveleges
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else 
    echo -e "$G PROCEED ::: $N You are running with root access" | tee -a $LOG_FILE
fi 

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi
}

dnf module disable redis -y &>>$LOG_FILE
VERIFY $? "Disabling default redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VERIFY $? "Enabling redis:7"

dnf install redis -y &>>$LOG_FILE
VERIFY $? "Installing Redis"

sed -i -e "s/127.0.0.1/0.0.0.0/" -e "/protected-mode/ c protected-mode no" /etc/redis/redis.conf
VERIFY $? "Editing conf file to enable remote connections"

systemctl enable redis &>>$LOG_FILE
systemctl start redis &>>$LOG_FILE
VERIFY $? "Starting Redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, Time taken = $Y $TOTAL_TIME $N secs" | tee -a $LOG_FILE