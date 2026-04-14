output "alb_dns" {
  value       = aws_lb.api_lb.dns_name        
  description = "URL pública del Load Balancer"
}

output "api_1_ip" {
  value = aws_instance.api1.public_ip        
}

output "api_2_ip" {
  value = aws_instance.api2.public_ip         
}

output "rabbitmq_ip" {
  value = aws_eip.rabbitmq_eip.public_ip
}

output "mongodb_ip" {
  value = aws_eip.mongodb_eip.public_ip
}