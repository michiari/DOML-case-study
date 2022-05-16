output "ip_address" {
  value = aws_instance.nginx-app.public_ip
}
