resource "aws_iam_role" "pen_tester" {
  name = "PenTester"
  assume_role_policy = data.aws_iam_policy_document.strict_env_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "read_only_access" {
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  role = aws_iam_role.pen_tester.name
}

resource "aws_iam_role_policy_attachment" "security_audit_access" {
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  role = aws_iam_role.pen_tester.name
}