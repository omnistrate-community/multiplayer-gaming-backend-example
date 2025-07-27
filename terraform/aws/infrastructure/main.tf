# AWS Infrastructure for Enterprise-Style Multiplayer Gaming Backend
# This module creates the foundational cloud infrastructure including:
# - S3 buckets for game assets and analytics
# - IAM roles for service authentication
# - CloudWatch resources for monitoring

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

# S3 Bucket for Game Assets
resource "aws_s3_bucket" "game_assets" {
  bucket = "enterprise-gaming-assets-{{ $sys.id }}"
  
  tags = {
    Name        = "GameAssets-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_s3_bucket_versioning" "game_assets_versioning" {
  bucket = aws_s3_bucket.game_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "game_assets_encryption" {
  bucket = aws_s3_bucket.game_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket for Analytics Data
resource "aws_s3_bucket" "analytics_data" {
  bucket = "enterprise-gaming-analytics-{{ $sys.id }}"
  
  tags = {
    Name        = "AnalyticsData-{{ $sys.id }}"
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_s3_bucket_versioning" "analytics_data_versioning" {
  bucket = aws_s3_bucket.analytics_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "player_service_logs" {
  name              = "/enterprise-gaming/player-service-{{ $sys.id }}"
  retention_in_days = 30
  
  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "PlayerService"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_cloudwatch_log_group" "game_session_logs" {
  name              = "/enterprise-gaming/game-session-{{ $sys.id }}"
  retention_in_days = 30
  
  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "GameSessionService"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_cloudwatch_log_group" "matchmaking_logs" {
  name              = "/enterprise-gaming/matchmaking-{{ $sys.id }}"
  retention_in_days = 30
  
  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "MatchmakingService"
    ManagedBy   = "Omnistrate"
  }
}

# IAM Role for Player Service
resource "aws_iam_role" "player_service_role" {
  name = "enterprise-gaming-player-service-{{ $sys.id }}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "{{ $sys.deploymentCell.oidcProviderArn }}"
        }
        Condition = {
          StringEquals = {
            "{{ $sys.deploymentCell.oidcProviderUrl }}:sub" = "system:serviceaccount:{{ $sys.deployment.namespace }}:player-service-sa"
            "{{ $sys.deploymentCell.oidcProviderUrl }}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "PlayerService"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_iam_role_policy" "player_service_policy" {
  name = "enterprise-gaming-player-service-policy-{{ $sys.id }}"
  role = aws_iam_role.player_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.game_assets.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.player_service_logs.arn}:*"
      }
    ]
  })
}

# IAM Role for Analytics Service
resource "aws_iam_role" "analytics_service_role" {
  name = "enterprise-gaming-analytics-service-{{ $sys.id }}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "{{ $sys.deploymentCell.oidcProviderArn }}"
        }
        Condition = {
          StringEquals = {
            "{{ $sys.deploymentCell.oidcProviderUrl }}:sub" = "system:serviceaccount:{{ $sys.deployment.namespace }}:analytics-service-sa"
            "{{ $sys.deploymentCell.oidcProviderUrl }}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "AnalyticsService"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_iam_role_policy" "analytics_service_policy" {
  name = "enterprise-gaming-analytics-service-policy-{{ $sys.id }}"
  role = aws_iam_role.analytics_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.analytics_data.arn,
          "${aws_s3_bucket.analytics_data.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for Kafka Service
resource "aws_iam_role" "kafka_service_role" {
  name = "enterprise-gaming-kafka-service-{{ $sys.id }}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "{{ $sys.deploymentCell.oidcProviderArn }}"
        }
        Condition = {
          StringEquals = {
            "{{ $sys.deploymentCell.oidcProviderUrl }}:sub" = "system:serviceaccount:{{ $sys.deployment.namespace }}:kafka-sa"
            "{{ $sys.deploymentCell.oidcProviderUrl }}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "KafkaService"
    ManagedBy   = "Omnistrate"
  }
}

# KMS Key for encryption
resource "aws_kms_key" "gaming_key" {
  description             = "KMS key for Enterprise Gaming Backend encryption"
  deletion_window_in_days = 7

  tags = {
    Environment = "{{ $var.environment }}"
    Service     = "Enterprise-Gaming-Backend"
    ManagedBy   = "Omnistrate"
  }
}

resource "aws_kms_alias" "gaming_key_alias" {
  name          = "alias/enterprise-gaming-{{ $sys.id }}"
  target_key_id = aws_kms_key.gaming_key.key_id
}

# Outputs
output "game_assets_bucket_name" {
  value = aws_s3_bucket.game_assets.id
  description = "Name of the S3 bucket for game assets"
}

output "game_assets_bucket_arn" {
  value = aws_s3_bucket.game_assets.arn
  description = "ARN of the S3 bucket for game assets"
}

output "analytics_bucket_name" {
  value = aws_s3_bucket.analytics_data.id
  description = "Name of the S3 bucket for analytics data"
}

output "analytics_bucket_arn" {
  value = aws_s3_bucket.analytics_data.arn
  description = "ARN of the S3 bucket for analytics data"
}

output "player_service_role_arn" {
  value = aws_iam_role.player_service_role.arn
  description = "ARN of the IAM role for player service"
}

output "analytics_role_arn" {
  value = aws_iam_role.analytics_service_role.arn
  description = "ARN of the IAM role for analytics service"
}

output "kafka_role_arn" {
  value = aws_iam_role.kafka_service_role.arn
  description = "ARN of the IAM role for Kafka service"
}

output "kms_key_id" {
  value = aws_kms_key.gaming_key.key_id
  description = "ID of the KMS key for encryption"
}

output "player_service_log_group" {
  value = aws_cloudwatch_log_group.player_service_logs.name
  description = "CloudWatch log group for player service"
}

output "game_session_log_group" {
  value = aws_cloudwatch_log_group.game_session_logs.name
  description = "CloudWatch log group for game session service"
}

output "matchmaking_log_group" {
  value = aws_cloudwatch_log_group.matchmaking_logs.name
  description = "CloudWatch log group for matchmaking service"
}
