# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "server_name" {
  description = "Name of the server"
  type        = string
}

variable "image" {
    description = "The image ID that will be used to create the instance"
    type = string
}

variable "server_type" {
    description = "The Hetzner server type that will be used to create the instance"
    type = string
}

variable "location" {
    description = "The Hetzner location code that will be used to create the instance"
    type = string
}

variable "ssh_keys" {
    description = "The public key that will be used to check ssh access"
    type = list(string)
}

variable "runcmd" {
    description = "The runcommand part of the cloud_init script"
    type = string
    default = ""
}

variable "username" {
    description = "The username for the created user on the server"
    type = string
    default = "sprantic"
}