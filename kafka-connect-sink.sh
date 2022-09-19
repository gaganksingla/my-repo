#!/bin/bash

# Make sure you change the ADV_HOST variable in docker-compose.yml
# if you are using docker Toolbox

# 1) Source connectors
# Start our kafka cluster
docker-compose up kafka-cluster elasticsearch postgres mongo
