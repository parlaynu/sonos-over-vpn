# Client Setup

## Wireguard Client

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

## Connection and Operating

To use the system:

* enable the personal hotspot on your mobile phone
* connect your tablet's wifi to the hotspot
* start the vpn on your tablet
* start your sonos app on your tablet and wait for it to discover your speakers

You might need to fully kill the app and start it again so it isn't trying to use any cached settings.

