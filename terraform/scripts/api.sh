#!/bin/bash

exec > /tmp/api.log 2>&1  # Log desde el inicio, sin set -e

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

# ── Sin --upgrade pip, sin --break-system-packages ─────────
pip3 install uvicorn fastapi pymongo pika python-dotenv --user

cat > /home/ec2-user/app/.env <<EOF
MONGO_URI=mongodb://user:admin@${MONGO_IP}:27017/main?authSource=admin
RABBITMQ_HOST=${RABBITMQ_IP}
RABBITMQ_PORT=5672
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_QUEUE=player_tasks
EOF

echo ".env generado:"
cat /home/ec2-user/app/.env

# ── user_data corre como root, uvicorn queda en /root/.local ─
nohup /root/.local/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 >> /tmp/api.log 2>&1 &
echo "uvicorn arrancado"