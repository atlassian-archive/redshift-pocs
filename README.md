# Redshift Proof of Concepts

This repository will contain proof of concept code related to Redshift
tutorials, blog posts, benchmarks, etc.

Details about the infrastructure needed to run this code can be found in
`./ops/README.md`.

Details about specific POCS can be found in
`./src/client/<POC_NAME>/README.md`.

## Requirements

- [Cmake](http://www.cmake.org/)
- [m4](http://www.gnu.org/software/m4/m4.html)
- [AWS CLI tools](https://aws.amazon.com/cli/)
- [psql](http://www.postgresql.org/docs/9.4/static/app-psql.html)

## Install

- Read `./ops/README.md` for details on how to spin up the
  infrastructure needed to run this code.
- Run `./configure`. This will use the AWS CLI tools to request
  information about the infrastructure provisioned in the previous step.

  ```
  ./configure \
    -DAWS_REGION=<YOUR_AWS_REGION> \
    -DAWS_CF_STACK_NAME=<YOUR_AWS_CLOUDFORMATION_STACK_NAME> \
    -DSSH_USERNAME=<YOUR_AWS_EC2_SSH_USERNAME> \
    -DAWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID> \
    -DAWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY> \
    -DCOMPONENT=client
  ```

  If you installed `m4` using `brew` on a Mac, you may need to specify
  the correct path to the `m4` binary.

  ```
  ./configure \
    -DAWS_REGION=<YOUR_AWS_REGION> \
    -DAWS_CF_STACK_NAME=<YOUR_AWS_CLOUDFORMATION_STACK_NAME> \
    -DSSH_USERNAME=<YOUR_AWS_EC2_SSH_USERNAME> \
    -DAWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID> \
    -DAWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY> \
    -DM4_BINARY=/usr/local/Cellar/m4/1.4.17/bin/m4 \
    -DCOMPONENT=client
  ```

- Run `make install`. This will create a directory called `./pocs` with
  all of the code needed to run the POCs.

## Uninstall

```
make uninstall
make clean
```
