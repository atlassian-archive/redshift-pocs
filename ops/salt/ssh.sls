ssh_server:
  pkg:
    - installed
    - name: openssh-server
  service:
    - running
    - enable: True
    - name: ssh
