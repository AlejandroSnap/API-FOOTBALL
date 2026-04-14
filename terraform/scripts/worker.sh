#!/bin/bash
set -e

# ── 1. Instalar dependencias ────────────────────────────────
yum update -y
yum install -y python3 python3-pip git aws-cli

# ── 2. Obtener IPs desde Parameter Store ───────────────────
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

# ── 3. Clonar repositorio ───────────────────────────────────
cd /home/ec2-user
git clone https://github.com/AlejandroSnap/API-FOOTBALL.git app
cd app

pip3 install -r requirements.txt

# ── 4. Crear .env — exactamente las vars que usa worker.py ─
cat > .env <<EOF
MONGO_URI=mongodb://user:admin@${MONGO_IP}:27017/main?authSource=admin

RABBITMQ_HOST=${RABBITMQ_IP}
RABBITMQ_PORT=5672
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_QUEUE=player_tasks
EOF

# ── 5. Arrancar el worker ───────────────────────────────────
cd /home/ec2-user/app
nohup python3 -m app.worker >> /var/log/worker.log 2>&1 &