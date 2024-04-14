variable "log_path" {
  description = "The path to the log file"
  type        = string
  default     = "/tmp/vscode-web.log"
}

variable "install_dir" {
  description = "The directory to install VS Code Web"
  type        = string
  default     = "/tmp/vscode-web"
}

resource "coder_script" "vscode-web" {
  agent_id     = var.agent_id
  display_name = "VS Code Web"
  icon         = "/icon/code.svg"
  script = templatefile("${path.module}/run.sh.tftpl", {
    workspace   = var.folder
    install_dir = var.install_dir
    log_path    = var.log_path
    port        = var.port
  })
  run_on_start = true
}
