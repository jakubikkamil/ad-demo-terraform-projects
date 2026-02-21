variable "tags" {
  type        = map(string)
  description = "Default tags to apply to all resources."
  default     = {}
}

variable "resource_prefix" {
  type        = string
  description = "Prefix used for naming resources (e.g. project or environment)."
  default     = ""
}

variable "location" {
  type        = string
  description = "Azure region where resources will be deployed."
}

variable "admins" {
  type        = list(string)
  description = "List of principal IDs (object IDs) with admin permissions."
  default     = []
}

variable "readers" {
  type        = list(string)
  description = "List of principal IDs with read-only permissions."
  default     = []
}

variable "data_writers" {
  type        = list(string)
  description = "List of principal IDs with data write permissions."
  default     = []
}

variable "data_readers" {
  type        = list(string)
  description = "List of principal IDs with data read permissions."
  default     = []
}
