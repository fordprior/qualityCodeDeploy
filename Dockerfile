FROM postman/newman_alpine33:latest

WORKDIR /etc
MKDIR /newman

ADD prod-check.postman_collection.json /etc/newman
