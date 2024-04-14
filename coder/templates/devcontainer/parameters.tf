data "coder_parameter" "repo_url" {
  name         = "repo_url"
  display_name = "Repository URL"
  description  = "The URL of the repository"
  mutable      = false
}

data "coder_parameter" "arch" {
  name         = "arch"
  display_name = "CPU Arch"
  description  = "The cpu arch to run on"
  default      = "amd64"
  icon         = "/icon/memory.svg"
  mutable      = false
  option {
    name  = "AMD / Intel"
    value = "amd64"
  }
  option {
    name  = "ARM / Apple Silicon"
    value = "arm64"
  }
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/container.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "6 GB"
    value = "6"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

data "coder_parameter" "docker" {
  name         = "docker"
  display_name = "Docker"
  description  = "Do you want a running Docker daemon?"
  type         = "bool"
  mutable      = true
  default      = false
}
