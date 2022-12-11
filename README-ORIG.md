# Sonos over VPN

This project describes how to acces and control your Sonos speakers using the app over a VPN connection.

I don't have a particularly good reason for doing this. I was motivated to figure it out because Sonos 
and the network protocols they use make this difficult ... not necessarily deliberately.

This could easily be adapted to work in scenarios where your Sonos speakers are on a different VLAN to
your wifi for example, which could be useful.

## Overview

There are four problems to overcome:

* the app only works on wifi networks
* the multicast service discovery protocol doesn't cross network boundaries
* 


Each is noted below with a description of how I have
addressed them.

Once the app has discovered the speakers and the speakers know about the app, the traffic seems to be normal
TCP unicast traffic and it all works smoothly... it's the discovery and setting up the initial connection
that needs special consideration.

### Problem #1: Need a Wifi Network

The app figures out if your device has a wifi connection, and if it doesn't, then it refuses to operate. So
your app device needs to be on a wifi network.

The way I use it is setup a hotspot on my mobile phone and then connect my tablet to it. Then start the
VPN on my tablet. When that's all up, I can start the Sonos app and control the speakers.

The two things I tried that failed were:

* using the vpn over a mobile phone data network: the App will detect that you don't have a wifi connection and refuse to work.
* using the vpn when connected to a third-party wifi network: it might be that my VPN was letting local traffic out and finding the Sonos speakers on the local network, but it didn't work; possibly operator error.

### Problem #2: Multicast Service Discovery 

You need a proxy to forward the multicast traffic across the LAN boundaries. I use `pimd` for this.

### Problem #3: TTL Set To 1

The TTL on the service discovery packet is set to 1 and needs to be incremented. 

I use an `iptables` rule (in the `mangle` table) to increment the TTL in the packets and send them 
happily into the second network.

### Problem #4: Return Traffic to App Host's Actual IP Address

It appears that the multicast service discovery protocol being used (so the app can find the speakers) sends
the IP address (and probably port) of the device running the app as part of the packet payload. This means
in this scenario, the speakers always want to talk back to the app on it's actual VPN IP address.

There are two consequences of this:

* can't have NAT anywhere between the app and the speakers
* the speakers need to be able to route traffic back to the VPN network

The solution I went with was to use DHCP to set the default route of the sonos speakers to be this VPN server.
More on this below.

## Prerequisites

There are a few things you need to setup manually to make this all work. They're described below.
Have a read through them - if you can't find a way to make them all work on your network, then
this isn't going to work for you.

### Admin Tools

* terraform (v1.3.2)
* ansible (core 2.13.5)

### RaspberryPi Server

These instructions are based on a RaspberryPi server with the Bullseye OS, 32bit lite version installed.
It will work on lots of other systems, but you'll need to adapt things.

Build the OS with the RaspberryPi Imager as described [here](https://www.raspberrypi.com/software/).

Set it up with ssh access enabled using public-key authentication.

Once it's built update the system with these commands:

    sudo apt update
    sudo apt dist-upgrade
    sudo reboot

### Sonos Speakers Default Route

The Sonos speakers need to have this VPN server as their default route. I tried adding a network route 
to the speakers for the VPN network, but no traffic ended up there - I presume that means that the speakers
only accept a default route from DHCP... or I did something wrong and haven't been back to test again.

I use a RaspberryPi running dnsmasq for my network services and use DHCP to set the default route
for the Sonos speakers. 

If you're just using your ISPs router, this might be difficult. Mine doesn't have a provision for
setting the default route... not even for the entire network let alone for individual machines.

If your router has the ability to set static routes, then you might be able to set a static route on 
your router to the VPN server for the VPN network. Then return traffic from the Sonos to the app will
first go to your router and then be sent on to the VPN server. Should work, but I haven't tested it.
 
### VPN Endpoint

To use your VPN, you need a way to access it from outside the network - this can be either a
DNS name or an IP address.

For DNS name, you can use a dynamic DNS provider and a lot of ISP routers have built in support
for dynamic DNS. Alternatively, if you have your own domain and DNS server, create an entry for 
this server there.

I use a cloud provider for my DNS and a 'roll-your-own-script' that runs daily as a cron job to 
check my current IP address from my ISP and programatically update the DNS entry if it has changed.

This can also just be the IP address your ISP grants you. However, this will probably change from
time to time so you'll need to update it in your client config occasionally.

### Firewall Port Forwarding

You will need to setup port forwarding on your ISP router to this internal server. How you do that
depends on your router - check it's documentation.

The default protocol and port are udp/51820.


## Post Configuration

port forwarding on your router
static route to vpn network

