output "endpoint" {
  value       = aws_db_instance.rds.endpoint
  description = "host:port for the RDS instance"
}

output "host" {
  value       = aws_db_instance.rds.address
  description = "Hostname only (no port)"
}

output "port" {
  value       = 5432
  description = "Listener port"
}

output "database" {
  value       = "app"
  description = "Initial database name created on first boot"
}

output "username" {
  value       = "app"
  description = "Master username"
}

# ── Durable credential store ──────────────────────────────────────────
# The credentials must outlive the process that created them. Before this,
# the ONLY copies were Terraform state and whatever the runner managed to
# write before something failed — so a run that died between "instance
# created" and "secret written" left a database nobody could log into.
#
# recovery_window_in_days = 0 on purpose: with the default 30-day window, a
# destroyed project cannot be re-provisioned under the same name ("secret
# already scheduled for deletion"), which breaks the pipeline's re-runnability
# for no benefit — this is not the last copy of the password (the Kubernetes
# Secret and the encrypted AppSecret hold it too).
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "dd-new-dev-db-db-credentials"
  description             = "Master credentials for the dd-new-dev-db postgres instance (managed by DeepAgent)"
  recovery_window_in_days = 0
  tags                    = {
    "ManagedBy" = "DeepAgent"
    "Database" = "dd-new-dev-db"
    "Engine" = "postgres"
    "Environment" = "dev"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  # The shape AWS's own rotation lambdas and most SDK helpers expect.
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.rds.address
    port     = 5432
    username = "app"
    password = var.db_master_password_override
    dbname   = "app"
    dbInstanceIdentifier = aws_db_instance.rds.identifier
  })
}

output "credentials_secret_arn" {
  value       = aws_secretsmanager_secret.db_credentials.arn
  description = "Secrets Manager ARN holding the master credentials. The ARN is safe to log; the value is not."
}

output "password" {
  value       = var.db_master_password_override
  sensitive   = true
  description = "Master password — pipe into a Kubernetes Secret; never log this."
}

output "connection_string" {
  value       = "postgres://app:${urlencode(var.db_master_password_override)}@${aws_db_instance.rds.address}:5432/app"
  sensitive   = true
  description = "Ready-to-use DATABASE_URL for the app pods"
}

output "security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS SG — inbound from the EKS worker SG"
}

output "db_subnet_group" {
  value       = aws_db_subnet_group.rds.name
  description = "DB subnet group the instance was placed in"
}

output "db_subnet_ids" {
  value       = local.db_subnet_ids
  description = "Subnets backing the DB subnet group (empty when reusing an existing group)"
}
