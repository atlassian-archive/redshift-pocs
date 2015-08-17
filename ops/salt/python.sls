python:
  pkg.installed

python-dev:
  pkg.installed

python-pip:
  pkg.installed

virtualenv:
  pip:
    - installed
    - require:
      - pkg: python-pip
