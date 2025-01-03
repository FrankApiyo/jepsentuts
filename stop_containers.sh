#! /bin/bash
for i in {1..3}; do sudo lxc-destroy n$i; done
