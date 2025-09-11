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
echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOGS_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOGS_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "$G SUCCESS ::: $N YOU ARE RUNNING WITH ROOT ACCESS" | tee -a $LOGS_FILE
fi

echo -e "$Y PLEASE ENTER ROOT PASSWORD TO SETUP $N" | tee -a $LOGS_FILE
read -s MYSQL_ROOT_PASSWORD

VERIFY(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOGS_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1 #give other than 0 upto 127
    fi
}

dnf install maven -y &>>$LOG_FILE
VERIFY $? "Install Maven and Java"

mkdir -p /app &>>$LOG_FILE
VERIFY $? "Creating App directory"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System user" roboshop &>>$LOG_FILE
    VERIFY $? "Creating Roboshop user"
else
    echo -e "Roboshop user is ... $Y Already Created $N" | tee -a $LOGS_FILE
fi

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VERIFY $? "Downloading Shipping component"

rm -rf /app/* &>>$LOG_FILE
cd /app &>>$LOG_FILE
unzip /tmp/shipping.zip &>>$LOG_FILE
VERIFY $? "Unzipping shipping"

mvn clean package &>>$LOG_FILE
VERIFY $? "Packaging in shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VERIFY $? "Moving and renaming the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VERIFY $? "Copying service file"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VERIFY $? "Starting Shipping service"

dnf install mysql -y &>>$LOG_FILE
VERIFY $? "Installing Mysql"

mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VERIFY $? "Loading data"
else
    echo -e "$Y Data is already Loaded $N" | tee -a $LOGS_FILE
fi

systemctl restart shipping &>>$LOG_FILE
VERIFY $? "Restarting the shipping service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $Y TIME TAKEN : $TOTAL_TIME sec $N" | tee -a $LOGS_FILE