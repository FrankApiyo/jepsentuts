#! /bin/bash

# Deps
sudo apt install -y lxc lxc-templates distro-info debootstrap bridge-utils libvirt-clients libvirt-daemon-system iptables ebtables dnsmasq-base libxml2-utils iproute2 bzip2 libnss-myhostname &&

  # Create VMs
  for i in {1..3}; do sudo lxc-create -n n$i -t debian -- --release bookworm --keyring /usr/share/keyrings/debian-archive-bookworm-stable.gpg; done &&

  # Add network cards
  for i in {1..3}; do
    sudo bash -c "cat >>/var/lib/lxc/n${i}/config <<EOF

# Network config
lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.link = virbr0
lxc.net.0.hwaddr = 00:1E:62:AA:AA:$(printf "%02x" $i)
EOF"
  done &&

  ## Point the resolver at the local libvirt DNSmasq server. This used to go in
  #/etc/dhcp/dhclient.conf and now systemd has done something horrible and
  #dhclient still exists but doesn't seem to be used
  echo "do we get here?" &&
  sudo bash -c "cat >/etc/systemd/network/1-lxc-dns.network <<EOF
[Match]
Name=en*

[Network]
DHCP=yes
DNS=192.168.122.1
EOF" &&

  # Start nodes
  for i in {1..3}; do
    sudo lxc-start -d -n n$i
  done &&

  ## SSH setup
  for i in {1..3}; do
    echo "setting up ssh and install sudo: ${i}" &&
      ## Set root password
      sudo lxc-attach -n n${i} -- bash -c 'echo "root:root" | chpasswd'
    sudo lxc-attach -n n${i} -- sed -i 's,^#\?PermitRootLogin .*,PermitRootLogin yes,g' /etc/ssh/sshd_config
    sudo lxc-attach -n n${i} -- sed -i 's,^#\?PasswordAuthentication .*,PasswordAuthentication yes,g' /etc/ssh/sshd_config
    sudo lxc-attach -n n${i} -- systemctl restart sshd &&
      echo "setting up ssh complete"
  done &&
  for i in {1..3}; do
    sudo lxc-attach -n n${i} -- apt install -y sudo
    sudo lxc-attach -n n${i} -- usermod -aG sudo root
  done &&

  ## Keyscan
  for i in {1..3}; do ssh-keyscan $(sudo lxc-info -i n${i} | awk '{print $2}'); done >>~/.ssh/known_hosts &&

  ## Create nodes file
  for i in {1..3}; do
    sudo lxc-info -i n${i} | awk '{print $2}' >>~/lxc-nodes
  done && echo "Node files created successfully" &&
  rm lxc-hosts.txt &&
  for i in {1..3}; do
    sudo lxc-info -i n${i} | awk '{print $2}' >>lxc-hosts.txt
  done
