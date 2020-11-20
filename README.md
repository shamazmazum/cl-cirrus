# cl-cirrus
[![Build Status](https://api.cirrus-ci.com/github/shamazmazum/cl-cirrus.svg)](https://cirrus-ci.com/github/shamazmazum/cl-cirrus)

This repository provides a replacement for `lispci/cl-travis` script for testing
Common Lisp systems with CirrusCI (since Travis is dead for OSS users). This
script can be downloaded form
[here](https://raw.githubusercontent.com/shamazmazum/cl-cirrus/master/install.sh). It
works in FreeBSD VMs provided by Cirrus and has support for SBCL, CCL and clisp.

## Example

Create `.cirrus.yml` file with the following content in your repository:

~~~~{.yml}
freebsd_instance:
  image_family: freebsd-12-1

task:
  env:
    matrix:
      - LISP: sbcl
      - LISP: ccl
      - LISP: clisp
  preinstall_script:
    - pkg upgrade -y
    - pkg install -y curl
  install_script:
    - curl -L https://raw.githubusercontent.com/shamazmazum/cl-cirrus/master/install.sh | sh
  script:
    - cl -l flexi-streams -e '(progn (print "Hello World") (uiop:quit))'
~~~~

It will compile `flexi-streams` and print "Hello World" using three different
Common Lisp implementations. Local systems may be cloned to `~/lisp` directory.
