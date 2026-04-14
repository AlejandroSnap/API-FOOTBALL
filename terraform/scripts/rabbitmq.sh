#!/bin/bash
set -e

# ── 1. Instalar RabbitMQ via Docker (más simple en EC2) ────
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# ── 2. Correr RabbitMQ con usuario guest habilitado ────────
docker run -d \
  --name rabbitmq \
  --restart always \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=user \
  -e RABBITMQ_DEFAULT_PASS=admin \
  rabbitmq:3-management

echo "[RabbitMQ] Corriendo en puerto 5672"
echo "[RabbitMQ] Panel web en puerto 15672"