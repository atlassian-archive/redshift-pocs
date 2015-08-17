#!/bin/bash

while getopts ":r:s:i:ch" opt; do
  case $opt in
    r)
      r=$OPTARG
      ;;
    s)
      s=$OPTARG
      ;;
    i)
      i=$OPTARG
      ;;
    c)
      c=1
      ;;
    h)
      h=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG. -h for help." >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument. -h for help." >&2
      exit 1
      ;;
  esac
done

if [ $h ]
then
  echo """
  Description:
  This script creates an AMI from a vagrant worker instance. It can optionally
  copy this AMI to all regions supported by Amazon Redshift.

  Options:
  -s    (Required) Cloudformation stack name.
  -r    (Required) Region of vagrant worker instance.
  -i    (Required) Instance ID of vagrant worker instance.
  -c               Optionally copy AMI to all regions supported by Amazon Redshift.
  -h               Print this help message and exit.
  """
  exit 0
fi

# `shred` might be better but it probably doesn't work as expected, plus it
# doesn't work recursively: http://techreport.com/forums/viewtopic.php?f=7&t=63399
echo "Removing sensitive and build-specific info."
AWS_REGION=$r vagrant ssh -c """
  sudo rm -rf /home/ubuntu/.*history
  sudo rm -rf /etc/ssh/*_key /etc/ssh/*_key.pub
  sudo rm -rf /home/ubuntu/.ssh/authorized_keys
  sudo rm -rf /srv/salt /etc/salt /var/log/salt
  sudo rm -rf /home/ubuntu/pocs/build /home/ubuntu/pocs/pocs/client
""" $s-worker

echo "Creating AMI"
CREATION_TIME=$(date +"%Y-%m-%dT%H-%M-%SZ")

AMI=$(
  aws --region $r ec2 create-image \
      --instance-id $i \
      --name "redshift-pocs-worker-$CREATION_TIME" \
      --description "Image for Redshift POC workers" | \
    awk -F\" '/ImageId/{print $4}'
)

AMI_STATE="pending"
while [ "$AMI_STATE" != "available" ]
do
  echo "Waiting for $AMI to become available."
  sleep 10
  AMI_STATE=$(
    aws --region $r ec2 describe-images \
        --image-ids $AMI | \
      awk -F\" '/State/{print $4}'
  )
done

echo "Making $AMI public"
aws --region $r ec2 modify-image-attribute \
  --image-id $AMI \
  --launch-permission "{\"Add\":[{\"Group\":\"all\"}]}"

# Specify -c to copy AMI to other regions
if [ $c ]
then
  # Redshift regions only
  REGIONS=(
    "us-east-1" "us-west-2" "eu-west-1" "eu-central-1" "ap-southeast-1" "ap-southeast-2"
    "ap-northeast-1"
  )

  for REGION in "${REGIONS[@]}"
  do
    if [[ "$REGION" != "$r" ]]; then
      echo "Copying $AMI to $REGION"
      COPIED_AMI=$(
        aws ec2 copy-image \
            --source-image-id $AMI \
            --source-region $r \
            --region $REGION \
            --name "redshift-pocs-worker-$CREATION_TIME" \
            --description "Image for Redshift POC workers" | \
          awk -F\" '/ImageId/{print $4}'
      )

      COPIED_AMI_STATE="pending"
      while [ "$COPIED_AMI_STATE" != "available" ]
      do
        echo "Waiting for $COPIED_AMI to become available."
        sleep 10
        COPIED_AMI_STATE=$(
          aws --region $REGION ec2 describe-images \
              --image-ids $COPIED_AMI | \
            awk -F\" '/State/{print $4}'
        )
      done

      echo "Making $COPIED_AMI public"
      aws --region $REGION ec2 modify-image-attribute \
        --image-id $COPIED_AMI \
        --launch-permission "{\"Add\":[{\"Group\":\"all\"}]}"
    fi
  done
fi

