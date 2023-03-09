resource "aws_acm_certificate" "cert" {
  domain_name = var.certificate_domain
  subject_alternative_names = [
    format("*.%s", var.certificate_domain)
  ]
  validation_method = "DNS"

  lifecycle {
    # to replace a certificate which is currently in use
    create_before_destroy = true
  }
}
