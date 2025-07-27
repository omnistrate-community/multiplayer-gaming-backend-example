# AWS Data Layer for Enterprise-Style Multiplayer Gaming Backend
# This module creates the data storage infrastructure including:
# - RDS instances for different game services
# - ElastiCache Redis cluster for caching and session management
# - DynamoDB tables for real-time data

provider "aws" {
  region = "{{ $sys.deploymentCell.region }}"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_security_group" {
  name        = "enterprise-gaming-rds-sg-{{ $sys.id }}"
  description = "Security group for RDS instances"
  vpc_id      = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-gaming-rds-sg-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    ManagedBy   = "Omnistrate"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache_security_group" {
  name        = "enterprise-gaming-elasticache-sg-{{ $sys.id }}"
  description = "Security group for ElastiCache instances"
  vpc_id      = "{{ $sys.deploymentCell.cloudProviderNetworkID }}"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "enterprise-gaming-elasticache-sg-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    ManagedBy   = "Omnistrate"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "gaming_db_subnet_group" {
  name       = "enterprise-gaming-db-subnet-group-{{ $sys.id }}"
  subnet_ids = [
    "{{ $sys.deploymentCell.privateSubnetIDs[0].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[1].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[2].id }}"
  ]

  tags = {
    Name        = "enterprise-gaming-db-subnet-group-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    ManagedBy   = "Omnistrate"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "gaming_cache_subnet_group" {
  name       = "enterprise-gaming-cache-subnet-group-{{ $sys.id }}"
  subnet_ids = [
    "{{ $sys.deploymentCell.privateSubnetIDs[0].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[1].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[2].id }}"
  ]

  tags = {
    Name        = "enterprise-gaming-cache-subnet-group-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    ManagedBy   = "Omnistrate"
  }
}

# RDS Instance for Player Data
resource "aws_db_instance" "player_database" {
  identifier     = "enterprise-gaming-player-db-{{ $sys.id }}"
  engine         = "mysql"
  engine_version = "8.0.37"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "players"
  username = "gaming_admin"
  password = "{{ $var.db_password }}"
  
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.gaming_db_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "07:00-09:00"
  maintenance_window     = "sun:09:00-sun:10:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  tags = {
    Name        = "enterprise-gaming-player-db-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "PlayerDatabase"
    ManagedBy   = "Omnistrate"
  }
}

# RDS Instance for Game Session Data
resource "aws_db_instance" "game_session_database" {
  identifier     = "enterprise-gaming-session-db-{{ $sys.id }}"
  engine         = "mysql"
  engine_version = "8.0.37"
  instance_class = "db.t3.large"
  
  allocated_storage     = 200
  max_allocated_storage = 2000
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "game_sessions"
  username = "gaming_admin"
  password = "{{ $var.db_password }}"
  
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.gaming_db_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "07:00-09:00"
  maintenance_window     = "sun:09:00-sun:10:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  tags = {
    Name        = "enterprise-gaming-session-db-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "GameSessionDatabase"
    ManagedBy   = "Omnistrate"
  }
}

# RDS Instance for Leaderboard Data
resource "aws_db_instance" "leaderboard_database" {
  identifier     = "enterprise-gaming-leaderboard-db-{{ $sys.id }}"
  engine         = "mysql"
  engine_version = "8.0.37"
  instance_class = "db.t3.medium"
  
  allocated_storage     = 50
  max_allocated_storage = 500
  storage_type         = "gp3"
  storage_encrypted    = true
  
  db_name  = "leaderboards"
  username = "gaming_admin"
  password = "{{ $var.db_password }}"
  
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.gaming_db_subnet_group.name
  
  backup_retention_period = 7
  backup_window          = "07:00-09:00"
  maintenance_window     = "sun:09:00-sun:10:00"
  
  skip_final_snapshot = true
  deletion_protection = false
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  
  tags = {
    Name        = "enterprise-gaming-leaderboard-db-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "LeaderboardDatabase"
    ManagedBy   = "Omnistrate"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "gaming_redis" {
  replication_group_id         = "enterprise-gaming-redis-{{ $sys.id }}"
  description                  = "Redis cluster for Enterprise Gaming Backend"
  
  node_type                    = "cache.t3.medium"
  port                        = 6379
  parameter_group_name        = "default.redis7"
  
  num_cache_clusters          = 3
  automatic_failover_enabled  = true
  multi_az_enabled           = true
  
  subnet_group_name          = aws_elasticache_subnet_group.gaming_cache_subnet_group.name
  security_group_ids         = [aws_security_group.elasticache_security_group.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  maintenance_window         = "sun:05:00-sun:06:00"
  snapshot_retention_limit   = 7
  snapshot_window           = "03:00-05:00"
  
  tags = {
    Name        = "enterprise-gaming-redis-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "RedisCache"
    ManagedBy   = "Omnistrate"
  }
}

# DynamoDB Table for Real-time Game State
resource "aws_dynamodb_table" "game_state" {
  name           = "enterprise-gaming-game-state-{{ $sys.id }}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  range_key      = "player_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "player_id"
    type = "S"
  }

  attribute {
    name = "game_mode"
    type = "S"
  }

  global_secondary_index {
    name     = "GameModeIndex"
    hash_key = "game_mode"
    range_key = "session_id"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "enterprise-gaming-game-state-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "GameStateTable"
    ManagedBy   = "Omnistrate"
  }
}

# DynamoDB Table for Player Sessions
resource "aws_dynamodb_table" "player_sessions" {
  name           = "enterprise-gaming-player-sessions-{{ $sys.id }}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "player_id"
  range_key      = "session_timestamp"

  attribute {
    name = "player_id"
    type = "S"
  }

  attribute {
    name = "session_timestamp"
    type = "N"
  }

  attribute {
    name = "region"
    type = "S"
  }

  global_secondary_index {
    name     = "RegionIndex"
    hash_key = "region"
    range_key = "session_timestamp"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name        = "enterprise-gaming-player-sessions-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "PlayerSessionsTable"
    ManagedBy   = "Omnistrate"
  }
}

# Redshift Cluster for Analytics (when analytics is enabled)
resource "aws_redshift_cluster" "analytics_warehouse" {
  count = var.enable_analytics ? 1 : 0
  
  cluster_identifier     = "enterprise-gaming-analytics-{{ $sys.id }}"
  database_name         = "gaming_analytics"
  master_username       = "analytics_admin"
  master_password       = "{{ $var.analytics_db_password }}"
  
  node_type             = "dc2.large"
  cluster_type          = "single-node"
  
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_redshift_subnet_group.analytics_subnet_group[0].name
  
  encrypted             = true
  skip_final_snapshot   = true
  
  tags = {
    Name        = "enterprise-gaming-analytics-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "AnalyticsWarehouse"
    ManagedBy   = "Omnistrate"
  }
}

# Redshift Subnet Group
resource "aws_redshift_subnet_group" "analytics_subnet_group" {
  count = var.enable_analytics ? 1 : 0
  
  name       = "enterprise-gaming-analytics-subnet-group-{{ $sys.id }}"
  subnet_ids = [
    "{{ $sys.deploymentCell.privateSubnetIDs[0].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[1].id }}",
    "{{ $sys.deploymentCell.privateSubnetIDs[2].id }}"
  ]

  tags = {
    Name        = "enterprise-gaming-analytics-subnet-group-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    ManagedBy   = "Omnistrate"
  }
}

# Outputs
output "player_db_endpoint" {
  value = aws_db_instance.player_database.endpoint
  description = "RDS endpoint for player database"
}

output "player_db_username" {
  value = aws_db_instance.player_database.username
  description = "Username for player database"
}

output "player_db_password" {
  value = aws_db_instance.player_database.password
  description = "Password for player database"
  sensitive = true
}

output "game_session_db_endpoint" {
  value = aws_db_instance.game_session_database.endpoint
  description = "RDS endpoint for game session database"
}

output "leaderboard_db_endpoint" {
  value = aws_db_instance.leaderboard_database.endpoint
  description = "RDS endpoint for leaderboard database"
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.gaming_redis.primary_endpoint_address
  description = "ElastiCache Redis primary endpoint"
}

output "redis_port" {
  value = aws_elasticache_replication_group.gaming_redis.port
  description = "ElastiCache Redis port"
}

output "game_state_table_name" {
  value = aws_dynamodb_table.game_state.name
  description = "DynamoDB table name for game state"
}

output "player_sessions_table_name" {
  value = aws_dynamodb_table.player_sessions.name
  description = "DynamoDB table name for player sessions"
}

output "analytics_warehouse_endpoint" {
  value = var.enable_analytics ? aws_redshift_cluster.analytics_warehouse[0].endpoint : null
  description = "Redshift analytics warehouse endpoint"
}
