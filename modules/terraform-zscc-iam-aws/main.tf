# Create IAM role and instance profile w/ SSM and Secrets Manager access policies

# Define AssumeRole access for EC2
data "aws_iam_policy_document" "instance-assume-role-policy" {
  version     = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Define AssumeRole access for CC callhome trust
data "aws_iam_policy_document" "cc-callhome-policy-document" {
  version     = "2012-10-17"
  statement {
    sid       = "AllowDelegationForCallhome"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = ["arn:aws:iam::223544365242:role/callhome-delegation-role"]
  }
}


# Create IAM Policy for CC callhome
resource "aws_iam_policy" "cc-callhome-policy" {
  count       = var.byo_iam_instance_profile == false && var.cc_callhome_enabled ? var.iam_count : 0
  description = "Policy which allows STS AssumeRole when attached to a user or role. Used for CC callhome"
  name        = "${var.name_prefix}-cc-${count.index + 1}-callhome-policy-${var.resource_tag}"
  policy      = data.aws_iam_policy_document.cc-callhome-policy-document.json
}

# Attach CC callhome policy to CC IAM Role
resource "aws_iam_role_policy_attachment" "cc-callhome-policy-attachment" {
  count      = var.byo_iam_instance_profile == false && var.cc_callhome_enabled ? var.iam_count : 0
  policy_arn = aws_iam_policy.cc-callhome-policy.*.arn[count.index]
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}

# AWS Managed Secrets Manager Policy
resource "aws_iam_role_policy_attachment" "SecretsManagerReadWrite" {
  count      = var.byo_iam_instance_profile == false ? var.iam_count : 0
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_smrw}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}

# AWS Managed SSM Manager Policy
resource "aws_iam_role_policy_attachment" "SSMManagedInstanceCore" {
  count = var.byo_iam_instance_profile == false ? var.iam_count : 0
  policy_arn = "arn:aws:iam::aws:policy/${var.iam_role_policy_ssmcore}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]
}



  
  

# Create CC IAM Role
resource "aws_iam_role" "cc-node-iam-role" {
  count = var.byo_iam_instance_profile == false ? var.iam_count : 0
  #count = local.valid_cc_create ? var.cc_count : 0
  name = var.iam_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-node-iam-role-${var.resource_tag}" : "${var.name_prefix}-cc-node-iam-role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json

  tags = merge(var.global_tags)
}

# Assign CC IAM Role to Instance Profile for CC instance attachment
resource "aws_iam_instance_profile" "cc-host-profile" {
  count = var.byo_iam_instance_profile == false ? var.iam_count : 0
  name       = var.iam_count > 1 ? "${var.name_prefix}-cc-${count.index + 1}-host-profile-${var.resource_tag}" : "${var.name_prefix}-cc-host-profile-${var.resource_tag}"
  role       = aws_iam_role.cc-node-iam-role.*.name[count.index]

  tags = merge(var.global_tags)
}
