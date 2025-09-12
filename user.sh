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
echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOG_FILE

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
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi 
}

dnf module disable nodejs -y &>>$LOG_FILE
VERIFY $? "Disabling default Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VERIFY $? "Enabling Nodejs version 20"

dnf install nodejs -y &>>$LOG_FILE
VERIFY $? "Instaling Nodejs:20"

mkdir -p /app &>>$LOG_FILE
VERIFY $? "Creating app directory"

id roboshop 
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VERIFY $? "Creating Roboshop user"
else
    echo -e "Roboshop user is .. $Y Already Created $N" | tee -a $LOG_FILE
fi

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VERIFY $? "Downloading user content"

rm -rf /app/* &>>$LOG_FILE
VERIFY "Removing default content in app directory"

cd /app &>>$LOG_FILE
unzip /tmp/user.zip &>>$LOG_FILE
VERIFY $? "Unzipping user content"

npm install &>>$LOG_FILE
VERIFY $? "Installing Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VERIFY $? "Copying service file"

systemctl daemon-reload &>>$LOG_FILE
VERIFY $? "Daemon-reload"

systemctl enable user &>>$LOG_FILE
systemctl start user &>>$LOG_FILE
VERIFY $? "Starting User"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $TOTAL_TIME ))

echo -e "Script execution completed successfully, $Y Time taken : $TOTAL_TIME secs $Y" | tee -a $LOG_FILE



