#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping"

mvn clean package  &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"

mv target/shipping-1.0.jar shipping.jar  &>>$LOG_FILE
VALIDATE $? "Moving and renaming Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Realod"

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling Shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping"

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Install MySQL"

# DB_EXISTS=$(mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD -sse "SHOW DATABASES LIKE 'cities';")
# if [ "$DB_EXISTS" != "cities" ]; then
#     mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD -e 'CREATE DATABASE cities;' &>> "$LOG_FILE"
#     VALIDATE $? "Creating cities database"

#     mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD cities < /app/db/schema.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading schema.sql"

#     mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD cities < /app/db/app-user.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading app-user.sql"

#     mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD cities < /app/db/master-data.sql &>> "$LOG_FILE"
#     VALIDATE $? "Loading master-data.sql"
# else
#     echo -e "Database data is $Y already loaded $N, skipping..." | tee -a "$LOG_FILE"
# fi

mysql -h mysql.kakuturu.store -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE


# START_TIME=$(date +%s)
# USERID=$(id -u)
# R="\e[31m"
# G="\e[32m"
# Y="\e[33m"
# N="\e[37m"

# LOGS_FOLDER="/var/log/roboshop-logs"
# SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
# LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# SCRIPT_DIR=$PWD

# mkdir -p $LOGS_FOLDER
# echo -e "Script started executing at : $Y $(date) $N" | tee -a $LOGS_FILE

# if [ $USERID -ne 0 ]
# then
#     echo -e "$R ERROR ::: $N PLEASE RUN WITH ROOT ACCESS" | tee -a $LOGS_FILE
#     exit 1 #give other than 0 upto 127
# else
#     echo -e "$G SUCCESS ::: $N YOU ARE RUNNING WITH ROOT ACCESS" | tee -a $LOGS_FILE
# fi

# echo -e "$Y PLEASE ENTER ROOT PASSWORD TO SETUP $N" | tee -a $LOGS_FILE
# read -s MYSQL_ROOT_PASSWORD

# VERIFY(){
#     if [ $1 -eq 0 ]
#     then 
#         echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOGS_FILE
#     else
#         echo -e "$2 is ... $R FAILURE $N" | tee -a $LOGS_FILE
#         exit 1 #give other than 0 upto 127
#     fi
# }

# dnf install maven -y &>>$LOG_FILE
# VERIFY $? "Install Maven and Java"

# mkdir -p /app &>>$LOG_FILE
# VERIFY $? "Creating App directory"

# id roboshop &>>$LOG_FILE
# if [ $? -ne 0 ]
# then
#     useradd --system --home /app --shell /sbin/nologin --comment "Roboshop System user" roboshop &>>$LOG_FILE
#     VERIFY $? "Creating Roboshop user"
# else
#     echo -e "Roboshop user is ... $Y Already Created $N" | tee -a $LOGS_FILE
# fi

# curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
# VERIFY $? "Downloading Shipping component"

# rm -rf /app/* &>>$LOG_FILE
# cd /app &>>$LOG_FILE
# unzip /tmp/shipping.zip &>>$LOG_FILE
# VERIFY $? "Unzipping shipping"

# mvn clean package &>>$LOG_FILE
# VERIFY $? "Packaging in shipping application"

# mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
# VERIFY $? "Moving and renaming the jar file"

# cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
# VERIFY $? "Copying service file"

# systemctl daemon-reload &>>$LOG_FILE
# systemctl enable shipping &>>$LOG_FILE
# systemctl start shipping &>>$LOG_FILE
# VERIFY $? "Starting Shipping service"

# dnf install mysql -y &>>$LOG_FILE
# VERIFY $? "Installing Mysql"

# mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
# if [ $? -ne 0 ]
# then
#     mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
#     mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
#     mysql -h mysql.kakuturu.store -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
#     VERIFY $? "Loading data"
# else
#     echo -e "$Y Data is already Loaded $N" | tee -a $LOGS_FILE
# fi

# systemctl restart shipping &>>$LOG_FILE
# VERIFY $? "Restarting the shipping service"

# END_TIME=$(date +%s)
# TOTAL_TIME=$(( $END_TIME - $START_TIME ))

# echo -e "Script execution completed successfully, $Y TIME TAKEN : $TOTAL_TIME sec $N" | tee -a $LOGS_FILE

