#create a hosted zone for 'zamanitech.online'
resource "aws_route53_zone" "main-zone" {
  name = "zamanitech.online"
}


#create an ALIAS recored for 'zamanitech.online' to resolve to ALB endpoint
resource "aws_route53_record" "DNS" {
  zone_id = aws_route53_zone.main-zone.zone_id
  name    = "zamanitech.online"
  type    = "A"

  alias {
    name                   = data.aws_alb.test.dns_name
    zone_id                = data.aws_alb.test.zone_id
    evaluate_target_health = true
  }
}

#create a customer asymmetric key for DNSSEC key signing key
resource "aws_kms_key" "dnssec-key" {
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode({
    Statement = [
      {
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign",
          "kms:Verify",
        ],
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Resource = "*"
        Sid      = "Allow Route 53 DNSSEC Service",
      },
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Resource = "*"
        Sid      = "Enable IAM User Permissions"
      },
    ]
    Version = "2012-10-17"
  })
}

#create a key signing key for DDNSSEC
resource "aws_route53_key_signing_key" "secure" {
  hosted_zone_id             = aws_route53_zone.main-zone.id
  key_management_service_arn = aws_kms_key.dnssec-key.arn
  name                       = "dnssec"
}

#create a DNSSEC Resourse for my domain name 'zamanitech.online'
resource "aws_route53_hosted_zone_dnssec" "dns" {
  depends_on = [
    aws_route53_key_signing_key.secure
  ]
  hosted_zone_id = aws_route53_key_signing_key.secure.hosted_zone_id
}

data "aws_caller_identity" "current" {}

data "aws_alb" "test" {
  arn = "arn:aws:elasticloadbalancing:us-east-1:230020307145:loadbalancer/app/demo-alb/740aadb463b6c932"
}
