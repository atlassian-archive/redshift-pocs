include:
  - python

awscli:
  pip:
    - installed
    - require:
      - pkg: python-pip

cfn:
  pip:
    - installed
    - name: https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
    - require:
      - pkg: python-pip
