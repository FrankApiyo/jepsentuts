#! /bin/bash
for i in {1..3}; do sudo lxc-stop n$i && sudo lxc-destroy n$i; done
