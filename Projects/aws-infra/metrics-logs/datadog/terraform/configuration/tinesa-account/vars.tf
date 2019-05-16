variable "datadog_api_key" {
  description = "Datadog API key. This can also be set via the DATADOG_API_KEY environment variable."
}

variable "datadog_app_key" {
  description = "Datadog APP key. This can also be set via the DATADOG_APP_KEY environment variable."
}

variable "account_alias" {
  description = "Account alias. This should match AWS account alias."
}
