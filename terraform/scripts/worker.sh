#!/bin/bash
set -e

dnf update -y
dnf install -y python3 python3-pip git

RABBITMQ_IP=$(aws ssm get-parameter \
  --name "/football/rabbitmq_ip" \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1)

MONGO_IP=$(aws ssm get-parameter \
  --name "/football/mongo_ip" \
  --query "Parameter.Value" \
  --output text \
  --region us-east-1)

cd /home/ec2-user
git clone https://github.com/AlejandroSnap/API-FOOTBALL.git app
cd app

pip3 install --upgrade pip
pip3 install uvicorn fastapi pymongo pika python-dotenv

cat > .env <<EOF
MONGO_URI=mongodb://user:admin@${MONGO_IP}:27017/main?authSource=admin
RABBITMQ_HOST=${RABBITMQ_IP}
RABBITMQ_PORT=5672
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_QUEUE=player_tasks
EOF

nohup python3 app/worker.py > /tmp/worker.log 2>&1 &