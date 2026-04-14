variable "aws_region" {
  default = "us-east-1"
}

variable "ami" {
  description = "AMI de Amazon Linux 2"
  default     = "ami-0ea87431b78a82070"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "vockey"
}

# ── Estos 4 son NUEVOS, los necesitas para el ALB ──────────
variable "vpc_id" {
  description = "ID de la VPC por defecto de AWS Academy"
}

variable "subnet_id" {
  description = "Subnet principal (misma zona que tus EC2)"
}

variable "subnet_id2" {
  description = "Segunda subnet (zona distinta, obligatoria para el ALB)"
}

variable "availability_zone" {
  description = "Zona de disponibilidad de tus EC2"
  default     = "us-east-1a"
}
# ───────────────────────────────────────────────────────────

variable "db_url" {
  description = "URL de conexión a MongoDB"
  sensitive   = true
  default     = "mongodb://user:admin@mongodb:27017/main?authSource=admin"
}

variable "rabbitmq_url" {
  description = "URL de RabbitMQ"
  sensitive   = true
  default     = "amqp://guest:guest@localhost:5672/"
}