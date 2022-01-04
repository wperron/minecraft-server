variable "app" {
  description = "application name"
  type        = string
}

variable "group" {
  description = "group who owns the app"
  type        = string
}

variable "ami_id" {
  description = "Amazon Machine Image ID"
  type        = string
}

variable "loki_username" {
  description = "Loki remote write username"
  type        = string
}

variable "loki_password" {
  description = "Loki remote write password"
  type        = string
}

variable "prom_username" {
  description = "Prometheus remote write username"
  type        = string
}

variable "prom_password" {
  description = "Prometheus remote write password"
  type        = string
}