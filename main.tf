provider "proxmox" {
  pm_tls_insecure = true
  /*
    // Credentials here or environment
    pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
    pm_password = "secret"
    pm_user = "terraform-user@pve"
    //Optional
    pm_otp = "otpcode"
  */
}

/* Uses cloud-init options from Proxmox 5.2 */
resource "proxmox_vm_qemu" "cloudinit-test" {
  name = "tftest1.xyz.com"
  desc = "tf description"
  target_node = "proxmox1-xx"

  clone = "ci-ubuntu-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  storage = "local"
  cores = 3
  sockets = 1
  memory = 2560
  disk_gb = 4
  nic = "virtio"
  bridge = "vmbr0"

  ssh_user = "root"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key root
-----END RSA PRIVATE KEY-----
EOF

  os_type = "cloud-init"
  ipconfig0 = "ip=10.0.2.99/16,gw=10.0.2.2"

  sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1kj...key1
ssh-rsa AAAAB3NzaC1kj...key2
EOF

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}

/* Uses custom eth1 user-net SSH portforward */
resource "proxmox_vm_qemu" "prepprovision-test" {
  name = "tftest1.xyz.com"
  desc = "tf description"
  target_node = "proxmox1-xx"

  clone = "terraform-ubuntu1404-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  cores = 3
  sockets = 1
  # Same CPU as the Physical host, possible to add cpu flags
  # Ex: "host,flags=+md-clear;+pcid;+spec-ctrl;+ssbd;+pdpe1gb"
  cpu = "host"
  numa = false
  memory = 2560
  scsihw = "lsi"
  # Boot from hard disk (c), CD-ROM (d), network (n)
  boot = "cdn"
  # It's possible to add this type of material and use it directly
  # Possible values are: network,disk,cpu,memory,usb
  hotplug = "network,disk,usb"
  # Default boot disk
  bootdisk = "virtio0"
  network {
    id = 0
    model = "virtio"
  }
  network {
    id = 1
    model = "virtio"
    bridge = "vmbr1"
  }
  disk {
    id = 0
    type = virtio
    storage = local-lvm
    storage_type = lvm
    size = 4G
    backup = true
  }
  # Serial interface of type socket is used by xterm.js
  # You will need to configure your guest system before being able to use it
  serial {
    id = 0
    type = "socket"
  }
  preprovision = true
  ssh_forward_ip = "10.0.0.1"
  ssh_user = "terraform"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key terraform
-----END RSA PRIVATE KEY-----
EOF

  os_type = "ubuntu"
  os_network_config = <<EOF
auto eth0
iface eth0 inet dhcp
EOF

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }

  provisioner "proxmox" {
    action = "sshbackward"
  }
}
