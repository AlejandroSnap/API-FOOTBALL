#!/bin/bash
set -e

# ── 1. Instalar MongoDB via Docker ─────────────────────────
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker

# ── 2. Correr MongoDB con usuario admin ────────────────────
docker run -d \
  --name mongodb \
  --restart always \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=user \
  -e MONGO_INITDB_ROOT_PASSWORD=admin \
  -e MONGO_INITDB_DATABASE=main \
  mongo:6

echo "[MongoDB] Corriendo en puerto 27017"