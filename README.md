it's just pieces of worked enviroment of managing openvpn server and clients keys

ovpn server:
  - generate certs and manage ca and server
  - put keys to another storage server
  - send emails with instructions

storage server:
  - give vpn keys to clients through nginx and basic auth


added daemon to automate bash script with http requests from corp portal

TODO:
  - fix mail settings to send via gmail application token
  - update role because people get keys from another corp portal with gmail auth
