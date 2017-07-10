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
  * edit the Trust relationships as follows:
  ```
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
  ```
  
## 4. go to IAM and create a Amazon CodeDeploy service role
  * managed policies: attach the `AWSCodeDeploy` policy
  * call it `AWSCodeDeployDemo`
  
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
  * create the following files: http://docs.aws.amazon.com/codedeploy/latest/userguide/tutorials-wordpress-configure-content.html
  * type `cat > install_dependencies.sh`, copy the following, then hit `Ctrl+C` to finish file creation:
```
#!/bin/bash
yum groupinstall -y "Web Server" "MySQL Database" "PHP Support"
yum install -y php-mysql
```
  * create a start server file: `cat > start_server.sh`, copy the following, then hit `Ctrl+C` to finish file creation:
```
#!/bin/bash
service httpd start
service mysqld start
```
  * create a stop server file:  `cat > stop_server.sh`, copy the following, then hit `Ctrl+C` to finish file creation:
```
#!/bin/bash
isExistApp=`pgrep httpd`
if [[ -n  $isExistApp ]]; then
   service httpd stop
fi
isExistApp=`pgrep mysqld`
if [[ -n  $isExistApp ]]; then
    service mysqld stop
fi
```
  * create a change perms file: `cat > change_permissions.sh`, copy the following, then hit `Ctrl+C` to finish file creation:
```
#!/bin/bash
chmod -R 755 /var/www/html/WordPress
```
  * set all permissions on these scripts: `chmod +x /tmp/WordPress/scripts/*`
  
## 7. create an appspec.yml file for CodeDeploy
  * `cd ..` back out to the `/WordPress` directory
  * type `cat > appspec.yml`, copy the following, then hit `Ctrl+C` to finish file creation:
```
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html/WordPress
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: scripts/change_permissions.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300
      runas: root
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 300
      runas: root
```

## 8. install aws cli & codedeployagent
  * commands are as follows:
  ```
  curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
  python get-pip.py --user
  pip install awscli --user
  ```
  * now, configure it with these commands (the access keys can be generated on the console's Security Credentials page):
  ```
  aws configure
  AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
  AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
  Default region name [None]: us-east-1
  Default output format [None]: json
  ```
  * install codedeployagent with these commands:
  ```wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install
  chmod +x ./install
  sudo ./install auto
  ```
## 9. upload your WordPress app to S3  
  * create bucket with name codedemoydeploybucket-fordprior and public read permissions
  * add a bucket policy as follows:
```
{
  "Statement": [
    {
      "Action": ["s3:PutObject", "s3:Get*", "s3:List*"],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::codedeploydemobucket-fordprior/*",
      "Principal": {
        "AWS": [
          "arn:aws:iam::1234567890:role/AWSCodeDeploy-EC2-InstanceProfile"
        ]
      }
    }
  ]
}
```

## 10. push the app to s3
  * navigate to /tmp/WordPress directory and type `aws deploy create-application --application-name wordpress-app-fordprior`
  * type the following:
```
aws deploy push \
  --application-name wordpress-app-fordprior \
  --s3-location s3://codedeploydemobucket-fordprior/wordpress-app-fordprior.zip \
  --ignore-hidden-file
```

## 11. deploy the app
 * get the service role ARN by typing `aws iam get-role --role-name AWSCodeDeploy-EC2-InstanceProfile --query "Role.Arn" --output text`
 * type this:
 ```
 aws deploy create-deployment-group \
  --application-name wordpress-app-fordprior \
  --deployment-group-name wordpress-deployment-group-fordprior \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --ec2-tag-filters Key=Name,Value=CodeDeployDemo,Type=KEY_AND_VALUE \
  --service-role-arn arn:aws:iam::1234567890:role/AWSCodeDeploy
 ```
 * now deploy, as follows!
 ```
 aws deploy create-deployment \
  --application-name wordpress-app-fordprior \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name wordpress-deployment-group-fordprior \
  --s3-location bucket=codedeploydemobucket-fordprior,bundleType=zip,key=wordpress-app-fordprior.zip
 ```

  
