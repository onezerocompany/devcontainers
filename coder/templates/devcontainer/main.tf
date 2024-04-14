terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "kubernetes" {
  config_path = null
}

provider "google" {
  project = "onezero"
  region  = "us-central1"
}

provider "coder" {}
data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}

data "coder_external_auth" "github" {
  id = "primary-github"
}

locals {
  namespace = "coder"
  name      = "${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  repo_input = replace(
    data.coder_parameter.repo_url.value,
    try(regex("(?:https?://)?(?:www.)?github.com/+", data.coder_parameter.repo_url.value), ""),
    "",
  )
  repo       = strcontains(local.repo_input, "/") ? local.repo_input : "onezerocompany/${local.repo_input}"
  repo_owner = try(split("/", local.repo)[0], "")
  repo_name  = try(split("/", local.repo)[1], "")
}

module "vscode" {
  source   = "./vscode-app"
  agent_id = coder_agent.main.id
  folder   = "/workspaces/${local.repo_name}"
}

data "kubernetes_secret" "coder-github-container-registry" {
  metadata {
    name      = "coder-github-container-registry"
    namespace = local.namespace
  }
}

resource "kubernetes_deployment" "workspace" {
  metadata {
    name      = "coder-${local.name}"
    namespace = local.namespace
    labels = {
      "coder.owner"          = data.coder_workspace.me.owner
      "coder.owner_id"       = data.coder_workspace.me.owner_id
      "coder.workspace_id"   = data.coder_workspace.me.id
      "coder.workspace_name" = data.coder_workspace.me.name
    }
  }
  spec {
    replicas = data.coder_workspace.me.start_count
    selector {
      match_labels = {
        "coder.workspace_id" = data.coder_workspace.me.id
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          "coder.workspace_id" = data.coder_workspace.me.id
        }
      }
      spec {
        node_selector = {
          "kubernetes.io/arch" = data.coder_parameter.arch.value
        }

        init_container {
          name  = "coder-init"
          image = "ghcr.io/onezerocompany/settings-gen"
          security_context {
            privileged = true
          }
          volume_mount {
            name       = "docker-config"
            mount_path = "/root/.docker/config.json"
            sub_path   = "config.json"
          }
          volume_mount {
            name       = "workspaces"
            sub_path   = local.repo_name
            mount_path = "/workspace"
          }
          volume_mount {
            name       = "vscode-settings"
            mount_path = "/vscode-settings"
          }
        }

        dynamic "container" {
          for_each = data.coder_parameter.docker.value == true ? [1] : []
          content {
            name  = "dind"
            image = "docker:dind"
            security_context {
              privileged = true
            }
            volume_mount {
              name       = "docker-socket"
              mount_path = "/var/run/docker.sock"
            }
          }
        }

        container {
          name  = "coder-${local.name}"
          image = "ghcr.io/coder/envbuilder:0.2.9"
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.main.token
          }
          env {
            name  = "CODER_AGENT_URL"
            value = data.coder_workspace.me.access_url
          }
          env {
            name  = "GIT_URL"
            value = "https://github.com/${local.repo}"
          }
          env {
            name  = "GIT_USERNAME"
            value = data.coder_external_auth.github.access_token
          }
          env {
            name  = "DOCKER_CONFIG_BASE64"
            value = base64encode(data.kubernetes_secret.coder-github-container-registry.data[".dockerconfigjson"])
          }
          env {
            name  = "INIT_SCRIPT"
            value = coder_agent.main.init_script
          }
          env {
            name  = "FALLBACK_IMAGE"
            value = "ghcr.io/onezerocompany/base:latest"
          }
          volume_mount {
            name       = "workspaces"
            mount_path = "/workspaces"
          }
          volume_mount {
            name       = "kube-config"
            mount_path = "/kube-config"
          }
          volume_mount {
            name       = "vscode-settings"
            mount_path = "/vscode-settings"
          }
          dynamic "volume_mount" {
            for_each = data.coder_parameter.docker.value == true ? [1] : []
            content {
              name       = "docker-socket"
              mount_path = "/var/run/docker.sock"
            }
          }
        }
        volume {
          name = "workspaces"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.workspaces.metadata.0.name
          }
        }
        volume {
          name = "vscode-settings"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.vscode-settings.metadata.0.name
          }
        }
        volume {
          name = "docker-config"
          secret {
            secret_name = "coder-github-container-registry"
            items {
              key  = ".dockerconfigjson"
              path = "config.json"
            }
          }
        }
        volume {
          name = "kube-config"
          secret {
            secret_name = "coder-kube-config"
            items {
              key  = "config"
              path = "config"
            }
          }
        }
        dynamic "volume" {
          for_each = data.coder_parameter.docker.value == true ? [1] : []
          content {
            name = "docker-socket"
            host_path {
              path = "/var/run/docker.sock"
            }
          }
        }
      }
    }
  }
}
