# create iam policy and role for cluster_autoscaler

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "AmazonEKSClusterAutoscalerPolicy"
  description = "EKS Autoscaler policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Resource" : ["*"]
      },
      // Theses are write actions, you might want to restrict this permissions
      {
        "Effect" : "Allow",
        "Action" : [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        "Resource" : ["*"]
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role" "cluster_autoscaler" {
  name        = "cluster-autoscaler"
  description = "EKS Autoscaler Role"

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
            "${module.this.oidc_provider}:sub" : "system:serviceaccount:kube-system:${var.cluster_autoscaler_arn_identifier}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  roles      = [aws_iam_role.cluster_autoscaler.name]
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}