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

mkdir -p $LOGS_FOLDER &>>$LOG_FILE
echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOG_FILE
    exit 1
else
    echo -e "$G SUCCESS ::: $N YOU ARE RUNNING WITH ROOT ACCESS" | tee -a $LOG_FILE
fi 

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ...$G SUCCESS $N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is ...$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VERIFY $? "Installing python3"

mkdir -p /app &>>$LOG_FILE
VERIFY $? "Creating App Directory"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System user" roboshop &>>$LOG_FILE
    VERIFY $? "Creating Roboshop user"
else
    echo -e "Roboshop user is .. $Y Already Created $N" | tee -a $LOG_FILE
fi

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VERIFY $? "Downloading Payment component"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/payment.zip &>>$LOG_FILE
VERIFY $? "Unzipping payment"

pip3 install -r requirements.txt &>>$LOG_FILE
VERIFY $? "Installing Dependancies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VERIFY $? "Copying service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable payment &>>$LOG_FILE
systemctl start payment &>>$LOG_FILE
VERIFY $? "Starting Payment component"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y TIME TAKEN : $TOTAL_TIME secs $Y" | tee -a $LOG_FILE