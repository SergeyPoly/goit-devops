variable "bucket_name" {
  type        = string
  description = "Уникальное имя S3 бакета"
}

variable "table_name" {
  type        = string
  description = "Имя таблицы DynamoDB для state locking"
}