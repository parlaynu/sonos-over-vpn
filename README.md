# Sonos over VPN

This project describes how to remotely access and control your Sonos speakers using the app over a VPN 
connection into your home network. It uses 'terraform' and 'ansible' to build and configure the wireguard VPN 
server and creates wireguard configs for clients. It describes the manual steps you need to do to complete 
the setup.

I don't have a particularly good reason for doing this. I was motivated to figure it out because Sonos 
and the network protocols they use make this difficult ... not deliberately but by virtue of the protocols
being utilised and their default configurations. It was a challenge and a chance to learn a thing or two.

This could easily be adapted to work in scenarios where your Sonos speakers are on a different VLAN to
your wifi, which could be useful.

These instructions assume that you run a very simple network with just your ISP provided router on your local
network. If you're doing something more advanced, some of the details below will be different, but if you
are doing advanced things, you will be easily able to adapt these instructions.

## Network Capabilities

Before getting too far into this, it's worth verifying that your network can provide two essential services
this setup requires:

* port forwarding from the internet side of your ISP provided router to an internal machine
* the ability to configure static routes

I've seen ISP provided routers that can't configure static routes so it's worth verifying this before you go any
further.

Port forwarding is pretty standard. For my router, from the web management console, browse to:

    'Security' -> 'Apps and Gaming' -> 'Single Port Forwarding' -> 'Add new Single Port Forwarding'

For static routes, from the web management console, browse to:

    'Connectivity' -> 'Advanced Routing' -> 'Add Static Route'

If you don't have equivalent features, then this isn't going to work for you.

## Overview

There are four problems to overcome:

* the app only works on wifi networks
* the multicast service discovery protocol doesn't cross network boundaries
* the service discovery packets have a TTL of 1
* return traffic from the speakers to the app use the app's actual IP address

The build and operational instructions below address all these issues.

Once the app has discovered the speakers and the speakers know about the app, the traffic seems to be normal
unicast traffic and it all works smoothly... it's the discovery and setting up the initial connection
that needs special consideration.

### Problem #1: Wifi Network

The app checks if your device is on a wifi network, and if it isn't, then it refuses to operate.

The way I use it is setup a hotspot on my mobile phone and then connect my tablet to it. Then start the
VPN on my tablet. When that's all up, I can start the Sonos app and control the speakers.

I tried using this when connected to a third-party wifi network and it failed. I didn't dig too deeply,
but I think the app was locating both the Sonos speakers on the local network and the speakers over the VPN
and getting confused. 

### Problem #2: Multicast Service Discovery 

A multicast router is needed to forward the discovery packets between networks. The build installs 'pimd' for this
and it works seemlessly with the default configuration.

### Problem #3: TTL Set To 1

Forwarding the packest isn't enough on it's own - as the packet TTL is 1, the packets won't make it into
the other network without some additional work.

An 'iptables' rule (in the 'mangle' table) is used to increment the TTL in the packets and send them 
happily into the second network.

This is setup automatically by the build.

### Problem #4: Return Traffic to App Host's Actual IP Address

It appears that the multicast service discovery protocol being used sends the IP address and port of 
the device running the app as part of the packet payload. This means in this scenario, the speakers 
always want to talk back to the app on it's actual VPN IP address.

There are two consequences of this:

* can't have NAT anywhere between the app and the speakers
* the speakers need to be able to route traffic back to the VPN network

There are a number of ways to make this work and they are things you will need to do manually. One
approach is using static routes on your ISP provided router and is documented below. 

Other approaches need more advanced networking setups and are up to you. I run my own network DNS/DHCP 
server with 'dnsmasq' and have configured the default route for the sonos speakers to be the VPN server. 
I tried setting a route for the VPN network only to the VPN server, but it didn't work for me - it appears
that the sonos speakers only accept a default route from DHCP.

## Prerequisites

There are a few things you need to setup manually to make this all work.

### Admin Tools

The build system uses [terraform](https://www.terraform.io/) and [ansible](https://www.ansible.com/) to 
build the configs and configure the raspberry pi server. 

I used these versions:

* terraform (v1.3.2)
* ansible (core 2.13.5)

### RaspberryPi Server

These instructions are based on a RaspberryPi server with the Bullseye OS, 32bit lite version installed.
It will work on lots of other systems, but you will most likely need to adapt some things.

Build the OS with the RaspberryPi Imager as described [here](https://www.raspberrypi.com/software/).

Set it up with ssh access enabled using public-key authentication.

Once it's built update the system with these commands:

    sudo apt update
    sudo apt dist-upgrade
    sudo reboot

Once you can ssh into the server without being prompted for a password, you're ready to go.

### Create DHCP Reservation for RaspberryPi Server

This is optional, but I recommend creating a DHCP reservation for this server so it's IP address will 
never change. This doesn't happen often, but it can and if it does, you will need to update configurations
on your router.

The first step is to find the the MAC and IP addresses of your server with this command:

    ifconfig eth0

The two lines of interest look like this:

    inet 192.168.1.21  netmask 255.255.255.0  broadcast 192.168.1.255
    ether b8:27:eb:81:53:de  txqueuelen 1000  (Ethernet)

Log into your ISP provided router and create the reservation. This will be different for all routers; for mine,
the process was to navigate through the menus to: 'Connectivity' -> 'Local Network' and select 'DHCP Reservations'. 
Enter the name, MAC address and IP address from above. For the example above, these values are:

    MAC address: b8:27:eb:81:53:de
    IP address: 192.168.1.21

### VPN Endpoint

To use your VPN, you need a way to access the endpoint from outside your home/work network - this can 
be either a DNS name or an IP address.

For the DNS name, you can use a dynamic DNS provider and a lot of ISP provided routers have built in support
for dynamic DNS. Now's a good time to set that up if you plan on using it.

This can also just be an IP address. However, this will probably change from time to time so you'll need 
to update it in your client config occasionally. A simple way to get your public IP address is with this:

    dig @resolver1.opendns.com +short myip.opendns.com

You will need this IP address to complete the steps below.

## Build

There are three steps to building this system:

* use terraform to create the ansible and wireguard configs
* use ansible to configure the server
* final manual steps

### Terraform

Terraform is where the configurations of your local network, the vpn network and the wireguard clients
are defined.

Copy the file 'terraform.tfvars.examples' to 'terraform.tfvars' and modify it for your configuration. It
should all be quite self explanatory.

You can add as many clients as you like to the client list and terraform will create configurations 
for each client.

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

### Manual Configuration

There are two things to setup manually to finish off the configuration:

* port forwarding on your router
* static route to vpn network

I'll describe how these work on my ISP provided router, but yours will probably be different.

### Port Forwarding

In the router web management console, browse to: 'Security' -> 'Apps and Gaming' -> 'Single Port Forwarding'
and select 'Add new Single Port Forwarding'. Enter the following in the dialog:

    Name: SonosVPN
    Protocol: UDP
    WAN Port: 51820
    LAN POrt: 51820
    Destination IP: IP address of you raspberry pi server

If you have changed the port in the configuration, you'll need to change those ports here as well.

### Static Routes

In the router web management console, browse to: 'Connectivity' -> 'Advanced Routing' and select 'Add Static Route'. 
Add the following (assuming you're using default VPN network settings):

    Router Name: SonosVPN
    Destination IP: 192.168.15.0
    Subnet Mask: 255.255.255.0
    Gateway: <internal network IP address of RaspberryPi server>

If you have configured a different 'cidr_block' for the 'vpn_network' you will need to use the new values 
in the 'DestinationIP' and 'Subnet Mask' fields.

## Using the System

### Wireguard Client

In the 'local/clients' directory, there are configurations for each client. They look like this:

    [Interface]
    Address = 192.168.15.7/24
    PrivateKey = <a private key>
    DNS = 1.1.1.1
    
    [Peer]
    PublicKey  = <a public key>
    AllowedIPs = 0.0.0.0/0
    Endpoint = AAA.BBB.CCC.DDD:51820

To install this configuration on a iPad assuming you're running on a mac, follow these steps:

* copy the client configuration to your icloud drive
* on your ipad, download the wireguard app from the app store
* click the '+' button and choose 'create from file or archive'
* browse to your icloud drive and select the configuration

That will install the vpn profile and you should be ready to go.

### Connection and Operating

To use the system:

* enable the personal hotspot on your mobile phone
* connect your tablet's wifi to the hotspot
* start the vpn on your tablet
* start your sonos app on your tablet and wait for it to discover your speakers

You might need to fully kill the app and start it again so it isn't trying to use any cached settings.

