# output "vpc_public_subnet" {
#   value = module.vpc.public_subnets
# }
# output "efs_config" {
#   value = aws_efs_file_system.efs
# }
# output "efs_access_point" {
#   value = aws_efs_access_point.efs_access_point
# }
# output "aws_efs_mount_target" {
#   value = aws_efs_mount_target.efs_mount
# }
# output "asg" {
#   value = module.auto_scaling
# }

output "elb_link" {
  value = module.elb_http.this_elb_dns_name
}