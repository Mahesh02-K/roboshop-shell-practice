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
echo "Script started executing at :: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ] #checking root privileges
then
    echo -e "$R ERROR $N:: PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "$Y You are running with root access $N" | tee -a $LOG_FILE
fi

VERIFY(){ #Verify function takes input as exit status and what command tried to install
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    fi
}

cp mongo.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
VERIFY $? "Copying mongo repo file"

dnf install mongodb-org -y &>>$LOG_FILE
VERIFY $? "Installing Mongodb server"

systemctl enable mongod &>>$LOG_FILE
systemctl start mongod &>>$LOG_FILE
VERIFY $? "Starting Mongodb"

sed -i "s/127.0.0.0/0.0.0.0/g" /etc/mongod.conf
VERIFY $? "Editing Mongod config file to enable remote connections"

systemctl restart mongod &>>$LOG_FILE
VERIFY $? "Restarting MongoDB"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y Time taken = $TOTAL_TIME $N secs " | tee -a $LOG_FILE