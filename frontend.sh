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
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ] #check root privileges
then
    echo -e "$R ERROR :::$N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1 
else
    echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

VERIFY(){ 
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
}

dnf module disable nginx -y &>>$LOG_FILE
VERIFY $? "Disabling default nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VERIFY $? "Enabling nginx:1.24"

dnf install nginx -y &>>$LOG_FILE
VERIFY $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx 
VERIFY $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VERIFY $? "Removing Default Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VERIFY $? "Downloading Frontend Content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VERIFY $? "Unzipping frontend Content"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VERIFY $? "Copying Nginx conf file"

systemctl restart nginx &>>$LOG_FILE
VERIFY $? "Restarting nginx"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed successfully, time taken is $Y $TOTAL_TIME secs $N" | tee -a $LOG_FILE






