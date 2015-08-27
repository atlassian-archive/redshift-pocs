## Overview

This directory contains [Vagrant](https://www.vagrantup.com/),
[Salt](http://saltstack.com/) and
[CloudFormation](https://aws.amazon.com/cloudformation/) code for provisioning
"development" and "production" versions of the infrastructure needed to support
the Redshift POCs in `../src`. The details of the infrastructure can be found
in `cf.json` but at a high level it includes:

- A VPC within which all infrastructure is deployed
- A Redshift cluster
- Optionally, a set of "workers" which are EC2 instances used to generate and
  load data into the cluster. In the future, these instances could potentially
  be reused for other workloads such as load testing the cluster.
- Optionally, a "client" EC2 instance from which the POC scripts can be run.
  These could also be run from your local machine.
- Optionally, an S3 bucket where manifest files used by Redshift's `COPY`
  command will be placed.

## Usage

### Using CloudFormation to Deploy the Infrastructure

```
aws --region <YOUR_AWS_REGION> cloudformation create-stack \
--stack-name <YOUR_AWS_CLOUDFORMATION_STACK_NAME> \
--template-body file://./cf.json \
--parameters \
ParameterKey=Environment,ParameterValue=prod \
ParameterKey=LocalIP,ParameterValue=<YOUR_LOCAL_IP_ADDRESS> \
ParameterKey=ClusterNodeCount,ParameterValue=4 \
ParameterKey=ClusterNodeType,ParameterValue=dc1.8xlarge \
ParameterKey=WorkerNodeCount,ParameterValue=4 \
ParameterKey=WorkerNodeType,ParameterValue=c3.8xlarge \
ParameterKey=KeyName,ParameterValue=<YOUR_AWS_SSH_KEY_NAME> \
ParameterKey=ProvisionClientDeps,ParameterValue=1 \
--capabilities CAPABILITY_IAM
```

For the full list and description of parameters that can be passed run:

```
aws --region <YOUR_AWS_REGION> cloudformation get-template-summary --template-body "$(< cf.json)"
```

### Using Vagrant to Deploy a Client

You can optionally deploy an EC2 instance to act as a client from which to run
the POC scripts. However, this is not required as you can build and run the
POC scripts from your local machine.

```
vagrant box add aws https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

AWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID> \
AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY> \
AWS_KEYPAIR_NAME=<YOUR_AWS_KEYPAIR_NAME> \
SSH_KEY_PATH=<YOUR_LOCAL_PATH_TO_AWS_KEYPAIR> \
AWS_REGION=<YOUR_AWS_REGION> \
vagrant up <YOUR_AWS_CLOUDFORMATION_STACK_NAME>-client
```

Before running this, make sure the following cloudformation parameter was
specified when provisioning the infrastructure:

```
ParameterKey=ProvisionClientDeps,ParameterValue=1
```

### Using Vagrant to Deploy a Development Worker

To add or test new functionality in the `../src/worker` directory you can spin
up a dev worker as follows:

```
vagrant box add aws https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

AWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID> \
AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY> \
AWS_KEYPAIR_NAME=<YOUR_AWS_KEYPAIR_NAME> \
SSH_KEY_PATH=<YOUR_LOCAL_PATH_TO_AWS_KEYPAIR> \
AWS_REGION=<YOUR_AWS_REGION> \
vagrant up <YOUR_AWS_CLOUDFORMATION_STACK_NAME>-worker
```

In order to SSH into the dev worker, make sure the following cloudformation
parameter was specified when provisioning the infrastructure:

```
ParameterKey=Environment,ParameterValue=dev
```

### Using Salt to Call Highstate Manually

There may be instances where you want to rerun highstate on a client or dev
worker. On instance creation, Vagrant takes care of passing some values to
Salt. You must manually provide this as follows:

```
sudo salt-call state.highstate \pillar='{"aws": {"AWS_ACCESS_KEY_ID": "<YOUR_AWS_ACCESS_KEY_ID>", "AWS_SECRET_ACCESS_KEY": "<YOUR_AWS_SECRET_ACCESS_KEY>", "region": "<YOUR_AWS_REGION>", "cf": { "stack": "<YOUR_AWS_CLOUDFORMATION_STACK_NAME>" } }, "component": "<client | worker>"}'
```

### Using `create-images.sh` to Create an AMI and Copy it to Other Regions

When a dev worker is ready to be packaged as an AMI, the `create-images.sh`
script can be used to create the AMI and copy it to all regions supported by
Redshift. For info on how to use this command run:

```
./create-images.sh -h
```

## Notes

- Ideally, workers would not be able to describe all clusters. Instead they
  would only be able to describe clusters in their VPC. However, it seems IAM
  policies for redshift only support `*` as a resource value:

  ```
  {
    "Action": "redshift:DescribeClusters",
    "Effect": "Allow",
    "Resource": "*"
  }
  ```
