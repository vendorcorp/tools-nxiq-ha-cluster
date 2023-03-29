variable "aws_region" {
  description = "AWS Region that our deployment is targetting"
  type        = string
  default     = "us-east-2"
}

variable "default_resource_tags" {
  description = "List of tags to apply to all resources created in AWS"
  type        = map(string)
  default = {
    environment : "development"
    purpose : "vendorcorp"
    owner : "phorton@sonatype.com"
    sonatype-group : "se"
    vendorcorp-purpose : "tools"
  }
}

# See https://docs.sonatype.com/display/OPS/Shared+Infrastructure+Initiative
variable "environment" {
  description = "Used as part of Sonatype's Shared AWS Infrastructure"
  type        = string
  default     = "production"
}

variable "pgsql_password" {
  description = "Password for the main account in PostgreSQL Cluster"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.pgsql_password) > 0
    error_message = "Root PostgreSQL password must be supplied."
  }
}
