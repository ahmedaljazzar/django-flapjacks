# Flapjacks

A Django project that automates transcoding videos on the cloud and
deploying them to Youtube easily so you can have a fall-back or reduce
the bandwidth cost once needed.

## The Infrastructure needed

This software heavily relies on infrastructure, so in case to avoid
creating things or modifying them mistakenly, we are going to install
[Terraform](https://www.terraform.io) as described
[here](https://www.terraform.io/intro/getting-started/install.html) and
to use its help to manage it.

From AWS, we are going to use the following services:
- AWS [S3](https://console.aws.amazon.com/s3/home) bucket:
    * The same bucket your machine is uploading videos to.
- AWS [SNS](https://console.aws.amazon.com/sns): Amazon Simple
Notification Service that contains a
[Topic](http://docs.aws.amazon.com/sns/latest/dg/CreateTopic.html),
which is an access point that allows subscribers, or "clients",
who are interested in receiving notifications about a specific topic,
to subscribe or request notifications.
- AWS [Elastic Transcoder](https://console.aws.amazon.com/elastictranscoder) With a pipeline:
    1. Linked to the bucket.
    1. Used _Elastic_Transcoder_Default_Role_ as a role.
    1. Allowed to send notifications using the created SNS topic
    for all possible events types (On Progressing, On Error,
    On Warning, and on Completion).
- AWS [Lambda Function](https://console.aws.amazon.com/lambda).
    - Roles:
        1. AmazonElasticTranscoderReadOnlyAccess
        1. AmazonElasticTranscoderJobsSubmitter
        1. AmazonS3FullAccess

    - Triggers:
        - **S3**: type: _ObjectCreated_ | Prefix: _{ROOT_PATH}_
        - **S3**: type: _ObjectRemoved_ | Prefix: _{OUTPUT_KEY_PREFIX}_
        - **S3**: type: _ObjectRemoved_ | Prefix: _{ROOT_PATH}_
        - **SNS** linked to the same created topic in the SNS service.

    > Where:
    >   - {ROOT_PATH} points to the dir you are uploading files into.
    >   - {OUTPUT_KEY_PREFIX} is the same as it's in the settings files.

- Youtube (Optional):
    - Needs a client secret file.
    - Needs also an oauth2 file to allow the Lambda uploading to
    Youtube without the user interactions.

    > IMPORTANT: Keep your oauth2 file in a safe place and give it
    the sufficient permissions no more!
    
    > IMPORTANT: Do not push the oauth2 file to a public repo.

