resource "aws_sqs_queue_policy" "repo_incoming_observability" {
  queue_url = aws_sqs_queue.repo_incoming_observability_queue.id
  policy    = data.aws_iam_policy_document.repo_incoming_observability_topic_access_to_queue.json
}

data "aws_iam_policy_document" "repo_incoming_observability_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.repo_incoming_observability_queue.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.repo_incoming.arn]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "suspensions_sns_topic_access_to_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      aws_sqs_queue.suspensions.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [data.aws_ssm_parameter.suspensions_sns_topic_arn.value]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "suspensions_subscription" {
  queue_url = aws_sqs_queue.suspensions.id
  policy    = data.aws_iam_policy_document.suspensions_sns_topic_access_to_queue.json
}