variable "ACCESS_KEY" { default = "secret-value-is-always-secret" }

variable "BUCKET_NAME" { default = "flapjacks" }

variable "BUCKET_REGION" { default = "us-east-1" }

variable "LAMBDA_FUNCTION_NAME" { default = "flapjacks_lambda_function"}

variable "LAMBDA_ROLE_NAME" { default = "flapjacks_lambda_role"}

variable "SECRET_KEY" { default = "secret-value-is-always-secret" }

variable "SNS_TOPIC_NAME" { default = "flapjacks_sns_topic" }

variable "TRANSCODER_NAME" { default = "flapjacks_video_transcoder" }

variable "TRANSCODER_ROLE_NAME" { default = "flapjacks_transcoder_role" }

variable "VIDEO_UPLOAD_LOCATION" { default = "videos/" }

variable "VIDEO_TRANSCODE_LOCATION" { default = "outputs/" }
