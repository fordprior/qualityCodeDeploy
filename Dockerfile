FROM sleyva97/python-dev

RUN apt update -y && \
      apt install git -y && \
      apt install curl -y

RUN git clone https://github.com/WordPress/WordPress.git /tmp/WordPress && \
      mkdir -p /tmp/WordPress/scripts

COPY scripts/ /tmp/WordPress/scripts

COPY appspec.yml /tmp/WordPress/appspec.yml

RUN pip install awscli --user && \
      source /tmp/WordPress/scripts/aws_creds.sh && \
      wget https://aws-codedeploy-us-east-1.s3.amazonaws.com/latest/install && \
      chmod +x ./install && \
      ./install auto && \

      aws deploy create-application --application-name wordpress-app-fordprior && \
      aws deploy push \
        --application-name wordpress-app-fordprior \
        --s3-location s3://codedeploydemobucket-fordprior/wordpress-app-fordprior.zip \
        --ignore-hidden-file && \

      aws deploy create-deployment-group \
        --application-name wordpress-app-fordprior \
        --deployment-group-name wordpress-deployment-group-fordprior \
        --deployment-config-name CodeDeployDefault.OneAtATime \
        --ec2-tag-filters Key=Name,Value=CodeDeployDemo,Type=KEY_AND_VALUE \
        --service-role-arn arn:aws:iam::1234567890:role/AWSCodeDeploy && \

        aws deploy create-deployment \
         --application-name wordpress-app-fordprior \
         --deployment-config-name CodeDeployDefault.OneAtATime \
         --deployment-group-name wordpress-deployment-group-fordprior \
         --s3-location bucket=codedeploydemobucket-fordprior,bundleType=zip,key=wordpress-app-fordprior.zip
