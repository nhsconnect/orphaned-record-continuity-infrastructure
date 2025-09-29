# The role from which Deployer can be assumed
resource "aws_iam_instance_profile" "deployer" {
  name = "Deployer"
  role = aws_iam_role.deployer.name
}

resource "aws_iam_role_policy_attachment" "deployer_admin_access" {
  role       = aws_iam_role.deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
