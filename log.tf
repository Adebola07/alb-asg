#create a vpc flow log
resource "aws_flow_log" "logs-flow" {
  iam_role_arn             = aws_iam_role.flowlog-role.arn
  log_destination          = aws_cloudwatch_log_group.vpc-flow.arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.my-vpc.id
  max_aggregation_interval = 60
}

#create a log group in cloudwatch to aggregate the logs
resource "aws_cloudwatch_log_group" "vpc-flow" {
  name = "vpc-flow-log"
}

#create role policy for vpc flow log
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#create a role for the vpc flow log
resource "aws_iam_role" "flowlog-role" {
  name               = "vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name   = "role-policy"
  role   = aws_iam_role.flowlog-role.id
  policy = data.aws_iam_policy_document.policy.json
}
