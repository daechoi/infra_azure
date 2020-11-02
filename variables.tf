variable "location" {}

variable "admin_username" {
  type = string
  description = "Administrator user name for virtual machine"
}

variable "admin_password" {
  type = string
  description = "Password must meet Azure complexity requirements"
}

variable "prefix" {
  type = string
  default = "my"
}

variable "tags" {
  type = map

  default = {
    Environment = "Terraform GS"
    Dept = "Engineering"
  }
}

variable "sku" {
  default = {
    westus2 = "16.04-LTS"
    eastus = "18.04-LTS"
  }
}

variable "managed_zone_name" {
  type = string
  description = "The name of the Google Cloud DNS managed Zone to add records to."
}

variable "project_id" {
  type = string
  default = ""
  description = "The id of the google API project that the given managed zone belongs to."
}

variable "recordsets" {
  type = list(object({
    name = string
    type = string
    ttl = number
    records = list(string)
  }))
  description = "List of DNS record objects to manage, in the standard terraforms structure."
}