#!/bin/bash
yum update -y
yum install -y python3 git

cd /home/ec2-user
git clone https://github.com/AlejandroSnap/API-FOOTBALL app
cd app

pip3 install -r requirements.txt

cat > .env <<EOF
DATABASE_URL=${db_url}
RABBITMQ_URL=${rabbitmq_url}
EOF

nohup uvicorn app.main:app --host 0.0.0.0 --port 8000 &