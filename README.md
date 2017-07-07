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
  * managed policies: attach the `AWSCodeDeploy-EC2-Permissions` policy
  * call it `AWSCodeDeploy-EC2-InstanceProfile`

## 4. go to EC2 and launch an Linux AMI
  * on step 3, for IAM Role select the role you created in that you created
  * on step 5, create a tag with key "Name" and value "AWSCodeDeploy"
  * download a `.pem` key and conver it to a `.ppk` using PuTTyGen
  * launch PuTTy shell and use your `.ppk` to SSH into your instance
  
## 5. install your website
  * type `sudo yum install git`
  * type `git clone https://github.com/WordPress/WordPress.git /tmp/WordPress`
  * type `cd /` and `ls` to see your app

## 6. write some scripts
  * `cd` into your `WordPress` directory
  * type `mkdir scripts`
  * create 4 files: `> install_dependencies.sh`, `> start_server.sh`, `> stop_server.sh`, and `> change_permissions.sh`
  * set all permissions on these scripts: `chmod +x /tmp/WordPress/scripts/*`
  
  
  
  
  
