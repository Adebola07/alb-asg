#create a public certificate for domain name 'zamanitech.online' 
resource "aws_acm_certificate" "my-cert" {
  domain_name       = "zamanitech.online"
  validation_method = "DNS"

  depends_on = [aws_route53_zone.main-zone]
}


#create a CNAME name record in 'zamanitech.online' hosted zone
resource "aws_route53_record" "CNAME" {
  for_each = {
    for dom-verify-opt in aws_acm_certificate.my-cert.domain_validation_options : dom-verify-opt.domain_name => {
      name    = dom-verify-opt.resource_record_name
      record  = dom-verify-opt.resource_record_value
      type    = dom-verify-opt.resource_record_type
      zone_id = aws_route53_zone.main-zone.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

#validate the onwership/control of the domain name 'zamanitech.online'
resource "aws_acm_certificate_validation" "validate" {
  certificate_arn         = aws_acm_certificate.my-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.CNAME : record.fqdn]
}
