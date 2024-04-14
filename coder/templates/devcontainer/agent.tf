resource "coder_agent" "main" {
  os                      = "linux"
  arch                    = data.coder_parameter.arch.value
  startup_script_behavior = "blocking"
  dir                     = "/workspaces/${local.repo_name}"

  env = {
    GITHUB_TOKEN : data.coder_external_auth.github.access_token
    KUBECONFIG : "/kube-config/config"
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace.me.owner_name, data.coder_workspace.me.owner)
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace.me.owner_name, data.coder_workspace.me.owner)
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }

  metadata {
    display_name = "CPU"
    key          = "1_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM"
    key          = "2_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path /workspaces"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "Arch"
    key          = "4_arch"
    script       = "uname -m"
    interval     = 60
  }
}
