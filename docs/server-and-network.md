# VPN Server and Network Setup

## Prerequisites

### Router Capabilities

There are two essential services this setup requires from your router:

* port forwarding from the internet side of your ISP provided router to an internal machine
* the ability to configure static routes

How you set this up will vary between routers, but here's how it is on mine.

Port forwarding is pretty standard: from the web management console, browse to:

    'Security' -> 'Apps and Gaming' -> 'Single Port Forwarding' -> 'Add new Single Port Forwarding'

For static routes, from the web management console, browse to:

    'Connectivity' -> 'Advanced Routing' -> 'Add Static Route'

If you don't have equivalent features, then this isn't going to work for you.

### Hardware

I built my setup on a RaspberryPi 3 Model B+ with the Bullseye OS, 32bit lite version installed.
It will work on lots of other systems, but you will most likely need to adapt some things.

Build the OS with the RaspberryPi Imager as described [here](https://www.raspberrypi.com/software/).

Set it up with ssh access enabled using public-key authentication.

Once it's built update the system with these commands:

    sudo apt update
    sudo apt dist-upgrade
    sudo reboot

Once you can ssh into the server without being prompted for a password, you're ready to go.

### Software

The project uses [terraform](https://www.terraform.io/) and [ansible](https://www.ansible.com/) to 
build the configs and configure the raspberry pi server. 

I used these versions:

* terraform (v1.3.2)
* ansible (core 2.13.5)

## Preparation

In the below sections, the following network addresses are used:

* home network: 192.168.1.0/24
* raspberry pi server: 192.168.1.21
* vpn network: 192.168.15.0/24

If your networks are different, you will need to use your correct settings in the below steps.

### Create DHCP Reservation for RaspberryPi Server

This step ensures that the IP address of your RaspberryPi won't change - it needs to be a well known 
address so that VPN traffic can be forwarded to it.

The first step is to find the the MAC and IP addresses of your server with this command:

    ifconfig eth0

The two lines of interest look like this:

    inet 192.168.1.21  netmask 255.255.255.0  broadcast 192.168.1.255
    ether b8:27:eb:81:53:de  txqueuelen 1000  (Ethernet)

Log into your ISP provided router and create the reservation. For my router, the process was to navigate 
through the menus to: 'Connectivity' -> 'Local Network' and select 'DHCP Reservations'. 
Enter the name, MAC address and IP address from above. For the example above, these values are:

    MAC address: b8:27:eb:81:53:de
    IP address: 192.168.1.21

Reboot your RaspberryPi and verify that the IP address is correctly set.

### Port Forwarding

In the router web management console, browse to: 'Security' -> 'Apps and Gaming' -> 'Single Port Forwarding'
and select 'Add new Single Port Forwarding'. Enter the following in the dialog:

    Name: SonosVPN
    Protocol: UDP
    WAN Port: 51820
    LAN POrt: 51820
    Destination IP: 192.168.1.21

If you have changed the port in the configuration, you'll need to change those ports here as well.

### Static Routes

In the router web management console, browse to: 'Connectivity' -> 'Advanced Routing' and select 'Add Static Route'. 
Add the following (assuming you're using default VPN network settings):

    Route Name: SonosVPN
    Destination IP: 192.168.15.0
    Subnet Mask: 255.255.255.0
    Gateway: 192.168.1.21

If you have configured a different 'cidr_block' for the 'vpn_network' you will need to use the new values 
in the 'DestinationIP' and 'Subnet Mask' fields.

### VPN Endpoint

To use your VPN, you need a way to access the endpoint from outside your home/work network - this can 
be either a DNS name or an IP address.

For the DNS name, you can use a dynamic DNS provider and a lot of ISP provided routers have built in support
for dynamic DNS. Now's a good time to set that up if you plan on using it.

This can also just be an IP address. However, this will probably change from time to time so you'll need 
to update it in your client config occasionally. A simple way to get your network's external, public IP address is 
with this:

    dig @resolver1.opendns.com +short myip.opendns.com

You will need this IP address to complete the steps below.

## Build

There are two steps to building this system:

* use terraform to create the ansible and wireguard configs
* use ansible to configure the server

### Terraform

Terraform is where the configurations of your local network, the vpn network and the wireguard clients
are defined.

Copy the file 'terraform.tfvars.examples' to 'terraform.tfvars' and modify it for your configuration. There
are four configuration blocks that need to be set, describing:

* the home network
* the vpn network
* the vpn server
* the vpn clients

You can add as many clients as you like to the client list and terraform will create a configuration
for each.

To run terraform:

    terraform init
    terraform apply

Once it finishes, the output is written to the directory 'local'. The client configurations can be found
in the 'clients' subdirectory.

### Ansible

Configuring the VPN server is fully automatic and quite straightforward. Simply run this command from
the root directory of the repository and it will set it up:

    ./local/ansible/run-ansible.sh

If you want to see what it's doing first, start with the file 'playbook.yml' and read through the roles;
there isn't a lot to it.
