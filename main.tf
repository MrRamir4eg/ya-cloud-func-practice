variable "cloud_id" {
  type        = string
  description = "ID облака в Yandex Cloud"
  default     = "b1gs982qr7h7c108d6vm"
  nullable    = false
}

variable "folder_name" {
  type        = string
  description = "Имя каталога в Yandex Cloud"
  nullable    = false
}

variable "key_file" {
  type        = string
  description = "Путь к авторизованному ключу сервисного аккаунта"
  nullable    = false
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = pathexpand(var.key_file)
  cloud_id                 = var.cloud_id
}

data "yandex_resourcemanager_folder" "folder" {
  name = var.folder_name
}

locals {
  folder_id          = data.yandex_resourcemanager_folder.folder.id
  folder_name        = data.yandex_resourcemanager_folder.folder.name
  folder_description = data.yandex_resourcemanager_folder.folder.description
}

resource "yandex_function" "get-ip-function" {
  name       = "${local.folder_name}-get-ip"
  user_hash  = "1.0.0"
  runtime    = "python312"
  entrypoint = "get_ip.handler"
  memory     = "128"
  folder_id = "${local.folder_id}"
  content {
    zip_filename = "${path.root}/get_ip.zip"
  }
}

resource "yandex_function_iam_binding" "function-iam" {
  function_id = "${yandex_function.get-ip-function.id}"
  role        = "functions.functionInvoker"
  members = [
    "system:allUsers",
  ]
}

resource "yandex_api_gateway" "api-gateway" {
  name        = "api-gw-${local.folder_name}-get-ip"
  description = "API Gateway для cloud function get-ip"
  folder_id   = local.folder_id
  spec        = templatefile("openapi.yml", {
    function_id = "${yandex_function.get-ip-function.id}"
  })
}

output "function_get_ip_url" {

  value = "https://${yandex_api_gateway.api-gateway.domain}"
}