data "aws_iam_policy_document" "transfer_complete_policy_doc" {
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
      aws_sqs_queue.transfer_complete.arn,
      aws_sqs_queue.transfer_complete_observability.arn
    ]

    condition {
      test     = "ArnEquals"
      values   = [data.aws_ssm_parameter.transfer_complete_topic_arn.value]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "transfer_complete_observability" {
  queue_url = aws_sqs_queue.transfer_complete_observability.id
  policy    = data.aws_iam_policy_document.transfer_complete_policy_doc.json
}

resource "aws_sqs_queue_policy" "transfer_complete" {
  queue_url = aws_sqs_queue.transfer_complete.id
  policy    = data.aws_iam_policy_document.transfer_complete_policy_doc.json
}
