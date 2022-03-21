#!/bin/bash -e

HOMESCRIPT=$(pwd)
RECIPIENTS="user1@example.com, user2@example.com"
TG_ADMINS='https://t.me/kirosvi'
OUT=/root/out
WEBDIR=/var/www/ovpn/protected
WEBDIR2=/var/www/corp/keys
REMOTEHOST="srv1"
REMOTEHOST2="srv2"
MAIL_DOMAIN="example.com"
SERVER_NAME="openvpn.example.com"
U=0
E=0
D=0
CREATE=0
REMOVE=0
OVPN_CONF=0
MANUAL_URL="http://example.com/mans/openvpn.html"
MANUAL_URL2="http://example.com/mans/openvpn-new.html"

mkdir -p $OUT


### Functions
function echo_help() {
    echo -e "\nUsage for $0:\n
    $0 [ -c -u <name.surname> -m <email> ]
    \nKeys:
    -c			action create
    -r			action remove
    -u <name.surname>	username.
    -m <email>		user email. may not use for local user.
    -h                    Show this help.\n"
}

function tobase64() {
	echo $1 | base64 -w 0
}

function is_user_exist() {
        USEREXIST=$(ssh $REMOTEHOST "find $WEBDIR -name $USERNAME.*" | wc -l)
        # Check for existance config for $USERNAME
        if [[ -d $OUT/"$USERNAME" ]]; then
                OVPN_CONF=1
        fi

        if [ $USEREXIST -ne 0 ] || [ $OVPN_CONF -ne 0 ]; then
                echo "Config already exist. Use another name or choose another user"
                echo "find local conf: $OVPN_CONF, and remote config: $USEREXIST"
                exit 0
        fi
}

function gen_cert() {
	# Create config
	cd ./easy-rsa-master/easyrsa3/
	./easyrsa gen-req $1 nopass batch
	./easyrsa sign-req client $1 batch
	cd $HOMESCRIPT
	# Create confdir
	if [ ! -f $OUT/$1 ]; then
	  mkdir $OUT/$1 -p
	fi
}
function create_config() {

	OPVPN_FILE=$(cat <<EOF
client
dev tun
proto tcp
connect-retry 1
connect-retry-max 1
remote $SERVER_NAME 12345
resolv-retry infinite
cipher AES-256-CBC
nobind
persist-key
persist-tun
comp-lzo
verb 3
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
<ca>
EOF
)
	#
	CONF_FILE=$OUT/$1/${1}.lin.ovpn
	echo "$OPVPN_FILE" > "$CONF_FILE"
	cat easy-rsa-master/easyrsa3/pki/ca.crt >> "$CONF_FILE"
	echo -e "</ca>\n<cert>" >> "$CONF_FILE"
	cat easy-rsa-master/easyrsa3/pki/issued/$1.crt >> "$CONF_FILE"
	echo -e "</cert>\n<key>" >> $CONF_FILE
	cat easy-rsa-master/easyrsa3/pki/private/$1.key >> "$CONF_FILE"
	echo -e "</key>" >> "$CONF_FILE"

}

function create_config_ubuntu_new() {

	OPVPN_FILE=$(cat <<EOF
client
dev tun
proto tcp
connect-retry 1
connect-retry-max 1
remote $SERVER_NAME 12345
resolv-retry infinite
cipher AES-256-CBC
nobind
persist-key
persist-tun
comp-lzo
verb 3
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved
down-pre
<ca>
EOF
)
	#
	CONF_FILE=$OUT/$1/${1}.lin-unew.ovpn
	echo "$OPVPN_FILE" > "$CONF_FILE"
	cat easy-rsa-master/easyrsa3/pki/ca.crt >> "$CONF_FILE"
	echo -e "</ca>\n<cert>" >> "$CONF_FILE"
	cat easy-rsa-master/easyrsa3/pki/issued/$1.crt >> "$CONF_FILE"
	echo -e "</cert>\n<key>" >> $CONF_FILE
	cat easy-rsa-master/easyrsa3/pki/private/$1.key >> "$CONF_FILE"
	echo -e "</key>" >> "$CONF_FILE"

}

function create_config_mac() {

        OPVPN_FILE=$(cat <<EOF
client
dev tun
proto tcp
connect-retry 1
connect-retry-max 1
remote $SERVER_NAME 12345
resolv-retry infinite
cipher AES-256-CBC
nobind
persist-key
persist-tun
comp-lzo
verb 3
script-security 2
<ca>
EOF
)
        #
        CONF_FILE=$OUT/$1/${1}.mac-win.ovpn
        echo "$OPVPN_FILE" > "$CONF_FILE"
        cat easy-rsa-master/easyrsa3/pki/ca.crt >> "$CONF_FILE"
        echo -e "</ca>\n<cert>" >> "$CONF_FILE"
        cat easy-rsa-master/easyrsa3/pki/issued/$1.crt >> "$CONF_FILE"
        echo -e "</cert>\n<key>" >> $CONF_FILE
        cat easy-rsa-master/easyrsa3/pki/private/$1.key >> "$CONF_FILE"
        echo -e "</key>" >> "$CONF_FILE"

}

function create_config_test() {
        # Create confdir
        if [ ! -f $OUT/$1 ]; then
          mkdir $OUT/$1 -p
        fi

        OPVPN_FILE=$(cat <<EOF
Hello world LIN!
EOF
)

        CONF_FILE=$OUT/$1/${1}.lin.ovpn
	echo "$OPVPN_FILE" > "$CONF_FILE"

}
function create_config_test_mac() {
        # Create confdir
        if [ ! -f $OUT/$1 ]; then
          mkdir $OUT/$1 -p
        fi

        OPVPN_FILE=$(cat <<EOF
Hello world MAC-WIN!
EOF
)

        CONF_FILE=$OUT/$1/${1}.mac-win.ovpn
	echo "$OPVPN_FILE" > "$CONF_FILE"

}

function remove_config() {

        cd /root/easy-rsa-master/easyrsa3/
        ./easyrsa --batch revoke $1
        EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
        cp pki/crl.pem /etc/openvpn/crl.pem
        chmod 0644 /etc/openvpn/crl.pem
	ssh $REMOTEHOST "sed -i \"/$1:.*/d\" /var/www/ovpn/.htpasswd;sed -i \"/^$/d\" /var/www/ovpn/.htpasswd"
	RUSERNAME=$(echo $1 | sed 's/.*\.//')
    exit 0
}

### Get options
while getopts "u:m:crh" options ;
do
  case $options in
  u)
    #USERNAME="$OPTARG"
    USERNAME="$(sed "s/ //g" <<< $OPTARG)"
    U=1
  ;;
  m)
    EMAIL="$OPTARG"
    E=1
  ;;
  c)
    CREATE=1
  ;;
  r)
    REMOVE=1
  ;;
  h)
    echo_help
    exit 0
  ;;
  *)
    echo " None defined options!"
    echo_help
    exit 0
  esac
OPTS="$OPTS$options"
done



if [[ $OPTS == "" ]]; then
  echo -n "None defined options"
  echo_help
  exit 0
fi

if [ ! -f /usr/bin/bashpass ]; then
  echo "install bash pass and setup dictionary '/usr/share/myspell/C.dic' #https://github.com/joshuar/bashpass"
fi
if [ ! -f /usr/bin/htpasswd ]; then
  echo "install htpasswd 'apt install apache2-utils' "
fi

### Check for valid collection of options
CHECK=$((CREATE+U))
if [ "$CHECK" -lt 2 ] && [ "$REMOVE" -eq 0 ]; then
  echo "Must specify 'user' and 'action' parametrs"
  exit 0
fi

CHECK2=$((CREATE+REMOVE))
if [[ "$CHECK2" -eq 2 ]]; then
  echo "You can't create and delete user at same time"
  exit 0
fi

CHECK3=$((REMOVE+U))
if [ "$CHECK3" -lt 2 ] && [ "$CREATE" -eq 0 ]; then
  echo "Must specify 'user' and 'action' parametrs2"
  exit 0
fi

# Get email for local user
if [[ "$E" -ne 1 ]]; then
  EMAIL="$USERNAME"@$MAIL_DOMAIN
fi

# MAIN
if [[ "$REMOVE" -eq 1 ]]; then
  remove_config $USERNAME
fi
if [[ "$CREATE" -eq 1 ]]; then
  is_user_exist

  #create_config $USERNAME
  #create_config_test $USERNAME
  #create_config_test_mac $USERNAME
  gen_cert $USERNAME
  create_config $USERNAME
  create_config_ubuntu_new $USERNAME
  create_config_mac $USERNAME

  if [[ $USEREXIST -eq 0 ]]; then
  	HASH=$(openssl rand -base64 125 | tr -d '\n' | sed "s/[/]//g;s/[+]//g;s/[=]//g;s/[-]//g")
  	USERPASS=$(bashpass -s -n2) #| sed "s/[/]//g;s/[+]//g;s/[=]//g;s/[-]//g")
  	HTPASSWD=$(htpasswd -nb $USERNAME $USERPASS | base64 -w 0)
  	URL="https://ovpn.$MAIL_DOMAIN/download/$HASH/$USERNAME.html"
  	FILE=$OUT/$USERNAME/${USERNAME}.lin.ovpn
  	FILE1=$OUT/$USERNAME/${USERNAME}.mac-win.ovpn
  	FILE2=$OUT/$USERNAME/${USERNAME}.lin-unew.ovpn
  	HTML=$(echo "<html><body><a href=./${USERNAME}.mac-win.ovpn download>${USERNAME}.mac-win.ovpn</a><br><a href=./${USERNAME}.lin.ovpn download>${USERNAME}.lin.ovpn</a><br><a href=./${USERNAME}.lin-unew.ovpn download>${USERNAME}.lin-unew.ovpn</a></body></html>" | base64 -w 0 )
  	# Make changes on $REMOTEHOST for user
  	ssh $REMOTEHOST "if [ $(find $WEBDIR/ -name ${USERNAME}.ovpn | wc -l) -eq 0 ]; then mkdir -p $WEBDIR/$HASH/;echo -n $HTPASSWD | base64 -d >> /var/www/ovpn/.htpasswd;sed -i \"/^$/d\" /var/www/ovpn/.htpasswd; echo -n $HTML | base64 -d >> $WEBDIR/$HASH/${USERNAME}.html; else echo -e \"User folder exist\"; fi"
  	scp $FILE $FILE1 $FILE2 $REMOTEHOST:$WEBDIR/$HASH/
  	scp $FILE $FILE1 $FILE2 $REMOTEHOST2:$WEBDIR2/

#  	ssh $REMOTEHOST2 "if [ $(find $WEBDIR2/ -name ${USERNAME}.ovpn | wc -l) -eq 0 ]; then mkdir -p $WEBDIR2/;echo -n $HTPASSWD | base64 -d >> /var/www/ovpn/.htpasswd;sed -i \"/^$/d\" /var/www/ovpn/.htpasswd; echo -n $HTML | base64 -d >> $WEBDIR2/${USERNAME}.html; else echo -e \"User folder exist\"; fi"
#  	scp $FILE $FILE1 $FILE2 $REMOTEHOST2:$WEBDIR2/

	# send email to admins
  	echo -e "Hello\nNew instructions for setup client You can find on ${MANUAL_URL2}" | mail -s "VPN settings" -aFrom:VPN\<denis.lisovsky@$MAIL_DOMAIN\> $RECIPIENTS
  	echo -e "\n\nOLD INSTRUCTIONS:\nThis is link for Your ovpn config: $URL \nYour login for link: $USERNAME\nYour pass for link You can get from 'Infra team' or contact us via Telegram: $TG_ADMINS \nInstructions for setup client You can find on ${MANUAL_URL}\n\n\n User pass: $USERPASS" | mail -s "VPN settings" -aFrom:VPN\<denis.lisovsky@$MAIL_DOMAIN\> $RECIPIENTS
  	# Send email whit instructions
  	echo -e "Hello\nInstructions for setup client You can find on ${MANUAL_URL2}" | mail -s "VPN settings" -aFrom:VPN\<denis.lisovsky@$MAIL_DOMAIN\> $USERNAME@$MAIL_DOMAIN

  fi
fi
