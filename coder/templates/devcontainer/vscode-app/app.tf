terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}

variable "agent_id" {
  description = "The ID of the coder agent"
  type        = string
  nullable    = false
}

variable "folder" {
  description = "The folder to open in the VS Code Web instance"
  type        = string
  default     = "/workspaces"
}

variable "port" {
  description = "The port to run the VS Code Web instance on"
  type        = number
  default     = 13338
}

data "coder_parameter" "share" {
  name         = "share"
  display_name = "Share with others"
  type         = "bool"
  mutable      = true
  default      = false
}

resource "coder_app" "vscode_web" {
  agent_id     = var.agent_id
  slug         = "vscode-web"
  display_name = "VS Code Web"
  url          = var.folder == null ? "http://localhost:${var.port}" : "http://localhost:${var.port}?folder=${var.folder}"
  icon         = "/icon/code.svg"
  subdomain    = true
  share        = data.coder_parameter.share.value == true ? "authenticated" : "owner"

  healthcheck {
    url       = "http://localhost:${var.port}/healthz"
    interval  = 5
    threshold = 6
  }
}
