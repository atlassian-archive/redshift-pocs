include:
  - aws

build-essential:
  pkg.installed

cmake:
  cmd:
    - run
    - name: |
        wget http://www.cmake.org/files/v3.3/cmake-3.3.0-Linux-x86_64.tar.gz
        tar -xzf cmake-3.3.0-Linux-x86_64.tar.gz
        cp -r cmake-3.3.0-Linux-x86_64/bin/* /usr/local/bin
        cp -r cmake-3.3.0-Linux-x86_64/share/cmake-3.3 /usr/local/share
    - cwd: /tmp
    - creates: /usr/local/bin/cmake

m4:
  pkg.installed

pocs:
  file:
    - recurse
    - name: /home/ubuntu/pocs
    - source: salt://pocs/code
    - user: ubuntu
    - group: ubuntu
    - clean: true

pocs_install:
  file:
    - managed
    - name: /home/ubuntu/pocs/configure
    - source: salt://pocs/code/configure
    - user: ubuntu
    - group: ubuntu
    - mode: 700
    - require:
      - file: pocs
  cmd:
    - run
    - name: |
        rm -rf build
        rm -rf pocs
        ./configure \
          -DAWS_ACCESS_KEY_ID={{ pillar['aws']['AWS_ACCESS_KEY_ID'] }} \
          -DAWS_SECRET_ACCESS_KEY={{ pillar['aws']['AWS_SECRET_ACCESS_KEY'] }} \
          -DAWS_REGION={{ pillar['aws']['region'] }} \
          -DAWS_CF_STACK_NAME={{ pillar['aws']['cf']['stack'] }} \
          -DSSH_USERNAME=ubuntu \
          -DCOMPONENT={{ pillar['component'] }}
        make install
    - cwd: /home/ubuntu/pocs
    - user: ubuntu
    - group: ubuntu
    - require:
      - pkg: build-essential
      - cmd: cmake
      - pkg: m4
      - sls: aws
      - file: pocs
      - file: pocs_install
