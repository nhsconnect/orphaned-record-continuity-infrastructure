variable "region" {
  default = "eu-west-2"
}

variable "vpn_port" {
  default = 443
}

variable "repo_name" {
  type = string
  default = "prm-deductions-base-infra"
}

#TODO: put allowed users here
variable "users" {
  default = [
    "tomzo",          # Tomasz Setkowski
    "phil",           # Phil Evans
    "helen.zhou",     # Helen Zhou
    "rosieamphlett",  # Rosie Amphlett
    "bfisher",        # Brett Fisher
    "robert",         # Robert Joscelyne
    "dorota",         # Dorota Sobkow
    "jamesgreen",     # James Green
    "matthewpeers"    # Matthew Peers
  ]
}
