terraform {
  required_version = ">= 1.5.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "this" {
  name       = "${var.name}-ssh"
  public_key = var.ssh_public_key
}

resource "hcloud_firewall" "this" {
  name = "${var.name}-fw"

  # Lock SSH down
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.allowed_ssh_cidrs
    description = "SSH"
  }

  # WireGuard UDP
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = tostring(var.wg_port)
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "WireGuard"
  }

  # Optional ping
  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "ICMP"
  }
}

resource "hcloud_server" "this" {
  name        = var.name
  server_type = var.server_type
  location    = var.location

  # Bootstrap OS only. nixos-anywhere will replace it.
  image = var.bootstrap_image

  ssh_keys     = [hcloud_ssh_key.this.id]
  firewall_ids = [hcloud_firewall.this.id]
}
