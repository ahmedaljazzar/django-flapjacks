provider "aws" {
  access_key = "${var.ACCESS_KEY}"
  secret_key = "${var.SECRET_KEY}"
  region = "${var.BUCKET_REGION}"
}

// Creating and configuring the base bucket
resource "aws_s3_bucket" "flapjacks_bucket" {
  bucket = "${var.BUCKET_NAME}"
  acl = "public-read"
}

// Creating an SNS topic to manage the notifications
resource "aws_sns_topic" "flapjacks_transcoding_notifications" {
  name = "${var.SNS_TOPIC_NAME}"
}

// Creating all needed IAM roles

// The transcoder role
resource "aws_iam_role" "flapjacks_transcoder_default_role" {
  name = "${var.TRANSCODER_ROLE_NAME}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "sns.amazonaws.com",
          "s3.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": "1"
    }
  ]
}
POLICY
}
resource "aws_iam_role_policy" "flapjacks_transcoder_default_policy" {
  name = "${var.TRANSCODER_ROLE_NAME}_policy"
  role = "${aws_iam_role.flapjacks_transcoder_default_role.id}"

  policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Allow",
      "Action": [
        "s3:Put*",
        "s3:ListBucket",
        "s3:*MultipartUpload*",
        "s3:Get*"
      ],
      "Resource": "${aws_s3_bucket.flapjacks_bucket.arn}"
    },
    {
      "Sid": "2",
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
    },
    {
      "Sid": "3",
      "Effect": "Deny",
      "Action": [
        "s3:*Delete*",
        "s3:*Policy*",
        "sns:*Remove*",
        "sns:*Delete*",
        "sns:*Permission*"
      ],
      "Resource": [
        "${aws_s3_bucket.flapjacks_bucket.arn}",
        "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
      ]
    }
  ]
}
POLICY
}

// The lambda role
resource "aws_iam_role" "flapjacks_lambda_default_role" {
  name = "${var.LAMBDA_ROLE_NAME}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "flapjacks_lambda_policy" {
  name = "${var.LAMBDA_ROLE_NAME}_policy"
  role = "${aws_iam_role.flapjacks_lambda_default_role.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:List*",
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.flapjacks_bucket.arn}"
    },
    {
      "Action": [
        "elastictranscoder:Read*",
        "elastictranscoder:List*",
        "elastictranscoder:Read*",
        "elastictranscoder:List*",
        "elastictranscoder:*Job",
        "elastictranscoder:*Preset"
      ],
      "Effect": "Allow",
      "Resource": "${aws_elastictranscoder_pipeline.flapjacks_transcoder.arn}"
    },
    {
      "Action": [
        "sns:List*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
    },
    {
      "Action": [
        "iam:List*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.flapjacks_transcoder_default_role.arn}"
    }
  ]
}
POLICY
}

// Creating the presets of the videos output
resource "aws_elastictranscoder_preset" "flapjacks_desktop_mp4" {
  container = "mp4"
  description = "Flapjacks desktop MP4 preset"
  name = "flapjacks_desktop_mp4"

  audio = {
    audio_packing_mode = "SingleTrack"
    bit_rate = 160
    channels = 2
    codec = "AAC"
    sample_rate = 44100
  }

  audio_codec_options = {
    profile = "AAC-LC"
  }

  video = {
    bit_rate = "2400"
    codec = "H.264"
    fixed_gop = "true"
    display_aspect_ratio = "auto"
    frame_rate = "auto"
    max_frame_rate = "29.97"
    keyframes_max_dist = 90
    max_height = "720"
    max_width = "1280"
    padding_policy = "NoPad"
    sizing_policy = "ShrinkToFit"
  }

  video_codec_options = {
    InterlaceMode = "Progressive"
    Profile = "baseline"
    Level = "3.1"
    MaxReferenceFrames = 3
    ColorSpaceConversionMode = "None"
  }

  thumbnails = {
    format = "png"
    interval = 120
    max_width = "auto"
    max_height = "auto"
    padding_policy = "Pad"
    sizing_policy = "Fit"
  }
}
resource "aws_elastictranscoder_preset" "flapjacks_desktop_webm" {
  container = "webm"
  description = "Flapjacks desktop WEBM preset"
  name = "flapjacks_desktop_webm"

  audio = {
    audio_packing_mode = "SingleTrack"
    bit_rate = 160
    channels = 2
    codec = "vorbis"
    sample_rate = 44100
  }

  video = {
    bit_rate = "2400"
    codec = "vp8"
    display_aspect_ratio = "auto"
    frame_rate = "auto"
    fixed_gop = "true"
    max_frame_rate = "29.97"
    keyframes_max_dist = 90
    max_height = "720"
    max_width = "1280"
    padding_policy = "NoPad"
  }

  video_codec_options = {
    Profile = "0"
  }

  thumbnails = {
    format = "png"
    interval = 120
    max_width = "auto"
    max_height = "auto"
    padding_policy = "Pad"
    sizing_policy = "Fit"
  }

}
resource "aws_elastictranscoder_preset" "flapjacks_mobile_high" {
  container = "mp4"
  description = "Flapjacks desktop mobile high quality preset"
  name = "flapjacks_mobile_high"

  audio = {
    audio_packing_mode = "SingleTrack"
    bit_rate = 128
    channels = 2
    codec = "AAC"
    sample_rate = 44100
  }

  audio_codec_options = {
    profile = "AAC-LC"
  }

  video = {
    bit_rate = "1250"
    codec = "H.264"
    fixed_gop = "true"
    display_aspect_ratio = "auto"
    frame_rate = "auto"
    max_frame_rate = "25"
    keyframes_max_dist = 75
    max_height = "480"
    max_width = "854"
    padding_policy = "NoPad"
  }

  video_codec_options = {
    InterlaceMode = "Progressive"
    Profile = "baseline"
    Level = "3.1"
    MaxReferenceFrames = 3
    ColorSpaceConversionMode = "None"
    MaxBitRate = 1500
    BufferSize = 15000
  }

  thumbnails = {
    format = "png"
    interval = 120
    max_width = "auto"
    max_height = "auto"
    padding_policy = "Pad"
    sizing_policy = "Fit"
  }
}
resource "aws_elastictranscoder_preset" "flapjacks_mobile_low" {
  container = "mp4"
  description = "Flapjacks desktop mobile low quality preset"
  name = "flapjacks_mobile_low"

  audio = {
    audio_packing_mode = "SingleTrack"
    bit_rate = 128
    channels = 2
    codec = "AAC"
    sample_rate = 44100
  }

  audio_codec_options = {
    profile = "AAC-LC"
  }

  video = {
    bit_rate = "720"
    codec = "H.264"
    fixed_gop = "true"
    display_aspect_ratio = "auto"
    frame_rate = "auto"
    max_frame_rate = "25"
    keyframes_max_dist = 75
    max_height = "360"
    max_width = "640"
    padding_policy = "NoPad"
  }

  video_codec_options = {
    InterlaceMode = "Progressive"
    Profile = "baseline"
    Level = "3"
    MaxReferenceFrames = 3
    ColorSpaceConversionMode = "None"
    MaxBitRate = 1500
    BufferSize = 15000
  }

  thumbnails = {
    format = "png"
    interval = 120
    max_width = "auto"
    max_height = "auto"
    padding_policy = "Pad"
    sizing_policy = "Fit"
  }
}

// Creating a transcoding pipeline
resource "aws_elastictranscoder_pipeline" "flapjacks_transcoder" {
  name = "${var.TRANSCODER_NAME}"
  input_bucket = "${var.BUCKET_NAME}"
  output_bucket = "${var.BUCKET_NAME}"
  role = "${aws_iam_role.flapjacks_transcoder_default_role.arn}"

  notifications {
    completed = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
    warning = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
    progressing = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
    error = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
  }
}

// Createing Lambda function
resource "aws_lambda_function" "flapjacks_lambda_function" {
  function_name = "${var.LAMBDA_FUNCTION_NAME}"
  handler = "lambda_function.lambda_handler"
  filename = "lambda_function.zip"
  role = "${aws_iam_role.flapjacks_lambda_default_role.arn}"
  runtime = "python3.6"
  timeout = 8

  // TODO: Memory and timeout for youtube
  // TODO: VPC
  // TODO: source_code_hash = "${base64sha256(file("lambda_function.zip"))}"
}

// Adding execution permissions to the functions
resource "aws_lambda_permission" "flapjacks_allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.flapjacks_lambda_function.arn}"
  principal = "s3.amazonaws.com"
  source_arn = "${aws_s3_bucket.flapjacks_bucket.arn}"
}
resource "aws_lambda_permission" "flapjacks_allow_sns" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.flapjacks_lambda_function.arn}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
}

resource "aws_s3_bucket_notification" "flapjacks_bucket_notifications" {
  bucket = "${aws_s3_bucket.flapjacks_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.flapjacks_lambda_function.arn}"
    events = [
      "s3:ObjectRemoved:*"
    ]
    filter_prefix = "${var.VIDEO_UPLOAD_LOCATION}"
  }

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.flapjacks_lambda_function.arn}"
    events = [
      "s3:ObjectRemoved:*"
    ]
    filter_prefix = "${var.VIDEO_TRANSCODE_LOCATION}"
  }

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.flapjacks_lambda_function.arn}"
    events = [
      "s3:ObjectCreated:*"
    ]
    filter_prefix = "${var.VIDEO_UPLOAD_LOCATION}"
  }
}
resource "aws_sns_topic_subscription" "sns_status_notification" {
  endpoint = "${aws_lambda_function.flapjacks_lambda_function.arn}"
  protocol = "lambda"
  topic_arn = "${aws_sns_topic.flapjacks_transcoding_notifications.arn}"
}
