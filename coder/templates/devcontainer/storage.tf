data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk size"
  description  = "The size of the disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = true
  validation {
    min       = 10
    max       = 150
    monotonic = "increasing"
  }
}

resource "kubernetes_persistent_volume_claim" "workspaces" {
  metadata {
    name      = "coder-${local.name}-workspaces"
    namespace = local.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${local.name}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace.me.owner_id
      "com.coder.user.username"    = data.coder_workspace.me.owner
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace.me.owner_email
    }
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }
}

# 500mb vscode-settings volume
resource "kubernetes_persistent_volume_claim" "vscode-settings" {
  metadata {
    name      = "coder-${local.name}-vscode-settings"
    namespace = local.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${local.name}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace.me.owner_id
      "com.coder.user.username"    = data.coder_workspace.me.owner
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace.me.owner_email
    }
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "500Mi"
      }
    }
  }
}