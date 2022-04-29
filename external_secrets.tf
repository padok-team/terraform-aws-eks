# create iam policy and role for external secret

resource "aws_iam_policy" "external_secret" {
  name        = "AmazonEKSExternalSecretPolicy"
  description = "EKS External Secret policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource" : [
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:*"
      ]
    }]
  })
  tags = var.tags
}

resource "aws_iam_role" "external_secret" {
  name        = "external-secret"
  description = "EKS External Secret Role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "${module.this.oidc_provider_arn}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${module.this.oidc_provider}:sub" : "system:serviceaccount:external-secrets:${var.external_secret_arn_identifier}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "external_secret" {
  name       = "external-secret"
  roles      = [aws_iam_role.external_secret.name]
  policy_arn = aws_iam_policy.external_secret.arn
}