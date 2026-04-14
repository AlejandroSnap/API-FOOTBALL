#!/bin/bash
set -e

# ── 1. Instalar dependencias ────────────────────────────────
dnf update -y
dnf install -y python3 python3-pip git

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

# ── 4. Instalar dependencias como root (sin --user) ────────
pip3 install --upgrade pip
pip3 install uvicorn fastapi pymongo pika python-dotenv

# ── 5. Crear .env ───────────────────────────────────────────
cat > .env <<EOF
MONGO_URI=mongodb://user:admin@${MONGO_IP}:27017/main?authSource=admin
RABBITMQ_HOST=${RABBITMQ_IP}
RABBITMQ_PORT=5672
RABBITMQ_USER=user
RABBITMQ_PASSWORD=admin
RABBITMQ_QUEUE=player_tasks
EOF

# ── 6. Arrancar la API ──────────────────────────────────────
nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 > /tmp/api.log 2>&1 &