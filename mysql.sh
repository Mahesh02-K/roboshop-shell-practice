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

#check root previleges
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "$G SUCCESS ::: $N YOU ARE RUNNING WITH ROOT ACCESS" | tee -a $LOG_FILE
fi

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $G FAILURE $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi
}

dnf install mysql-server -y &>>$LOG_FILE
VERIFY $? "Installing mysql" 

systemctl enable mysqld &>>$LOG_FILE
systemctl start mysqld &>>$LOG_FILE
VERIFY $? "Starting mysql"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y Time taken : $TOTAL_TIME secs $N" | tee -a $LOG_FILE