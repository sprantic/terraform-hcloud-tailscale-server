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
    description = "The public key that will be used to check ssh access. Fill only the first in the list"
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

variable "tailscale_api_key" {
    description = "Tailscale API key for device management (required for automatic cleanup on destroy)"
    type = string
    sensitive = true
}

variable "tailscale_tailnet" {
    description = "Tailscale tailnet name (e.g., 'example.com' or 'user@domain.com')"
    type = string
}

variable "docker_compose_yaml" {
    description = "Docker Compose YAML configuration to be deployed on the server"
    type = string
    default = ""
}

variable "docker_compose_project_name" {
    description = "Name for the Docker Compose project (defaults to server name)"
    type = string
    default = ""
}
