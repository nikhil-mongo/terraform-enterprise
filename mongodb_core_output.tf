output "project_id" {
  description = "The ID of the MongoDB Atlas Project needed to create the MongoDB Cluster"
  value       = mongodbatlas_project.mongo_project.id
}

output "mongodb_vpce_sg_id" {
  description = "The ID of the security needed to interact with the MongoDB private endpoint."
  value       = aws_security_group.mongodb_vpce_sg.id
}