# ── Security Group ──────────────────────────────────────────
resource "aws_security_group" "football_sg" {
  name        = "football_app_sg"
  description = "Security group para football API"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # FastAPI (tu puerto)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RabbitMQ
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RabbitMQ panel web
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MongoDB
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB escucha en puerto 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "football_app_sg"
  }
}

# ── EC2: API 1 ──────────────────────────────────────────────
resource "aws_instance" "api1" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.football_sg.id]
  user_data              = file("${path.module}/scripts/api.sh")
  availability_zone      = var.availability_zone
  iam_instance_profile   = "LabInstanceProfile"

  tags = {
    Name = "football-api-1"
    Role = "BackendAPI"
  }

  depends_on = [
    aws_ssm_parameter.rabbitmq_ip,
    aws_ssm_parameter.mongo_ip
  ]
}

# ── EC2: API 2 ──────────────────────────────────────────────
resource "aws_instance" "api2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.football_sg.id]
  user_data              = file("${path.module}/scripts/api.sh")
  availability_zone      = var.availability_zone
  iam_instance_profile   = "LabInstanceProfile"

  tags = {
    Name = "football-api-2"
    Role = "BackendAPI"
  }

  depends_on = [
    aws_ssm_parameter.rabbitmq_ip,
    aws_ssm_parameter.mongo_ip
  ]
}

# ── EC2: RabbitMQ ───────────────────────────────────────────
resource "aws_instance" "rabbitmq" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.football_sg.id]
  user_data              = file("${path.module}/scripts/rabbitmq.sh")
  availability_zone      = var.availability_zone

  tags = {
    Name = "rabbitmq-server"
    Role = "MessageBroker"
  }
}

# ── EC2: Worker ─────────────────────────────────────────────
resource "aws_instance" "worker" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.football_sg.id]
  user_data              = file("${path.module}/scripts/worker.sh")
  availability_zone      = var.availability_zone
  iam_instance_profile   = "LabInstanceProfile"

  tags = {
    Name = "worker-server"
    Role = "AsyncWorker"
  }

  depends_on = [
    aws_ssm_parameter.rabbitmq_ip,
    aws_ssm_parameter.mongo_ip
  ]
}

# ── EC2: MongoDB ────────────────────────────────────────────
resource "aws_instance" "mongodb" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.football_sg.id]
  user_data              = file("${path.module}/scripts/mongo.sh")
  availability_zone      = var.availability_zone

  tags = {
    Name = "mongodb-server"
    Role = "NoSQLDatabase"
  }
}

# ── IPs Estáticas (EIP) ─────────────────────────────────────
resource "aws_eip" "rabbitmq_eip" {
  instance = aws_instance.rabbitmq.id
  tags     = { Name = "rabbitmq-static-ip" }
}

resource "aws_eip" "mongodb_eip" {
  instance = aws_instance.mongodb.id
  tags     = { Name = "mongodb-static-ip" }
}

# ── Parameter Store ─────────────────────────────────────────
resource "aws_ssm_parameter" "rabbitmq_ip" {
  name  = "/football/rabbitmq_ip"
  type  = "String"
  value = aws_eip.rabbitmq_eip.public_ip
}

resource "aws_ssm_parameter" "mongo_ip" {
  name  = "/football/mongo_ip"
  type  = "String"
  value = aws_eip.mongodb_eip.public_ip
}

# ── Application Load Balancer ───────────────────────────────
resource "aws_lb" "api_lb" {
  name               = "football-lb-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.football_sg.id]
  subnets            = [var.subnet_id, var.subnet_id2]

  tags = { Name = "football-lb-api" }
}

# ── Target Group ────────────────────────────────────────────
resource "aws_lb_target_group" "api_tg" {
  name     = "football-api-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/players"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }
}

# ── Registrar las 2 APIs en el balanceador ──────────────────
resource "aws_lb_target_group_attachment" "api1" {
  target_group_arn = aws_lb_target_group.api_tg.arn
  target_id        = aws_instance.api1.id
  port             = 8000
}

resource "aws_lb_target_group_attachment" "api2" {
  target_group_arn = aws_lb_target_group.api_tg.arn
  target_id        = aws_instance.api2.id
  port             = 8000
}

# ── Listener: recibe en 80, manda a las APIs en 8000 ───────
resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.api_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}