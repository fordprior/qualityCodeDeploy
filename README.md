# qualityCodeDeploy
Steps for setting up a QA-friendly CI pipeline using GitHub, CircleCI, and AWS, where you can push a commit to a web app and run automated tests on it.

# Steps:
## 1. set up aws account (must provide credit card)
## 2. go to IAM and create a new custom policy
  * call it `AWSCodeDeploy-EC2-Permissions`
  * goal: to give the AWS CodeDeploy agent living on your EC2 instance access to the S3 bucket where your app lives
  * copy in this JSON (swap `fords-wordpress-app` with whatever you'll call your s3 bucket):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "arn:aws:s3:::fords-wordpress-app/*",
        "arn:aws:s3:::aws-codedeploy-us-east-1/*"
      ]
    }
  ]
}
```
## 3. go to IAM and create a Amazon EC2 service role.
  * managed policies: attach the `AWSCodeDeploy` & `CodeDeployDemo-EC2-Permissions` policies

