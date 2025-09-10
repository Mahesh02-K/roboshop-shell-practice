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
echo "Script started executing at : $(date)"

#check root previliges
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS"
    exit 1 #give other than 0 upto 127
else
    echo -e "$Y You are running with root access $N"
fi

VERIFY(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N"
    else
        echo -e "$2 is ... $R FAILURE $N"
        exit 1 #give other than 0 upto 127
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VERIFY $? "Disabling default version of nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VERIFY $? "Enabling version:20 of nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20"

mkdir -p /app 
VERIFY $? "Creating app directory"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VERIFY $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

#getting error if we use Below commented syntax instead of above syntax
# id roboshop
# if [ $? -ne 0 ]
# then 
#     echo -e "Roboshop user is $R Not Created $Y" | tee -a $LOG_FILE
#     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
#     VERIFY $? "Creating roboshop system user"
# else
#     echo -e "Roboshop user is "$Y Already Created $N" | tee -a $LOG_FILE
# fi

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VERIFY $? "Downloading Catalogue"

rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VERIFY $? "Unzipping Catalogue"

npm install &>>$LOG_FILE
VERIFY $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VERIFY $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue
VERIFY $? "Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongodb.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VERIFY $? "Installing mongodb client"

STATUS=$(mongosh --host mongodb.kakuturu.store --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.kakuturu.store </app/db/master-data.js &>>$LOG_FILE
    VERIFY $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e "Script execution completed successfully, $Y Time taken = $TOTAL_TIME $N secs" | tee -a $LOG_FILE