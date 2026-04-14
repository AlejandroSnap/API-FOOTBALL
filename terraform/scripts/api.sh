#!/bin/bash

exec > /tmp/api.log 2>&1  # Todo el log va aquí desde el inicio

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

echo "RABBITMQ_IP: $RABBITMQ_IP"
echo "MONGO_IP: $MONGO_IP"

cd /home/ec2-user
git clone https://github.com/AlejandroSnap/API-FOOTBALL.git app
cd app

# ── Sin --upgrade pip, con --break-system-packages ─────────
pip3 install uvicorn fastapi pymongo pika python-dotenv --break-system-packages

cat > .env <<EOF
MONGO_URI=mongodb://user:admin@${MONGO_IP}:27017/main?authSource=admin
RABBITMQ_HOST=${RABBITMQ_IP}
RABBITMQ_PORT=5672
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_QUEUE=player_tasks
EOF

echo ".env generado:"
cat .env

nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 >> /tmp/api.log 2>&1 &
echo "uvicorn arrancado"