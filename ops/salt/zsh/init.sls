include:
  - git

.zshrc:
  file:
    - managed
    - name: /home/ubuntu/.zshrc
    - source: salt://zsh/.zshrc
    - user: ubuntu
    - group: ubuntu

zsh:
  pkg.installed

oh-my-zsh:
  git:
    - latest
    - name: git://github.com/robbyrussell/oh-my-zsh.git
    - target: /home/ubuntu/.oh-my-zsh
    - user: ubuntu
    - require:
      - pkg: git
      - pkg: zsh
      - file: .zshrc

change-shell:
  user:
    - present
    - name: ubuntu
    - shell: /bin/zsh
    - require:
      - git: oh-my-zsh
