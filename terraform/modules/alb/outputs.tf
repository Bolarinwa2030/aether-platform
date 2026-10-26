output "dns_name" { value = aws_lb.main.dns_name }
output "arn_suffix" { value = aws_lb.main.arn_suffix }
output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.this : k => v.arn }
}