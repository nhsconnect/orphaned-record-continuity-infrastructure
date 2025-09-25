variable "region" {
  default = "eu-west-2"
}
variable "repo_name" {}
variable "environment" {}
variable "cluster_name" {}
variable "mhs_state_table_read_capacity" {}
variable "mhs_state_table_write_capacity" {}
variable "mhs_sync_async_table_read_capacity" {}
variable "mhs_sync_async_table_write_capacity" {}

variable "recipient_ods_code" {
  description = "ODS code that was used for the MHS (CMA endpoint) registration"
}

variable "inbound_queue_name" {
  default = "inbound"
}

variable "mhs_inbound_service_minimum_instance_count" {
  description = "The minimum number of instances of MHS inbound to run. This will be the number of instances deployed initially."
}

variable "mhs_log_level" {}

variable "mhs_outbound_service_minimum_instance_count" {
  description = "The minimum number of instances of MHS outbound to run. This will be the number of instances deployed initially."
}

variable "mhs_resynchroniser_max_retries" {
  description = "The number of retry attempts to the sync-async state store that should be made whilst attempting to resynchronise a sync-async message"
}

variable "mhs_resynchroniser_interval" {
  description = "Time between calls to the sync-async store during resynchronisation"
}

variable "mhs_forward_reliable_endpoint_url" {
  description = "The URL to communicate with Spine for Forward Reliable messaging from the outbound service"
}

variable "mhs_asynchronous_reliable_endpoint_url" {}

variable "mhs_synchronous_endpoint_url" {
  description = "The URL to communicate with Spine for synchronous messaging"
}

variable "mhs_spine_request_max_size" {
  description = "The maximum size of the request body (in bytes) that MHS outbound sends to Spine. This should be set minus any HTTP headers and other content in the HTTP packets sent to Spine."
  default     = "9999600" # This is 5 000 000 - 400 ie 5MB - 400 bytes, roughly the size of the rest of the HTTP packet
}

variable "build_id" {
  description = "ID used to identify the current build such as a commit sha."f
  default = "2.0.1"
}

variable "deregistration_delay" {
  default = 30
}

variable "allowed_mhs_clients" {
  default     = "10.0.0.0/8"
  description = "Network from which MHS ALBs should allow connections"
}

variable "spine_cidr" {
  description = "Network where spine services are located"
}

variable "cluster_suffix" {}

variable "spine_org_code" {}

variable "mhs_vpc_cidr_block" {}

variable "mhs_outbound_lookup_method" {}

variable "allow_vpn_to_ecs_tasks" {
  default = false
}

variable "allow_vpn_to_mhs_outbound_lb" {
  default = false
}
