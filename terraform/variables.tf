variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "name" {
  type    = string
  default = "wg-vps"
}

variable "location" {
  type    = string
  default = "nbg1"
}

variable "server_type" {
  type    = string
  default = "cx23"
}

variable "bootstrap_image" {
  type    = string
  default = "ubuntu-24.04"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key contents (ssh-ed25519 ...)."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH."
  default     = ["0.0.0.0/0", "::/0"]
}

variable "wg_port" {
  type    = number
  default = 51820
}
