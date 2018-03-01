#!/bin/bash

set -e

ca=selfca_ca
server=selfca_server
domains=""
common_name=""
overwrite=0
days=3650
org="Self CA"

usage()
{
   echo "Usage:"
   echo "   $0  -d <domain1> [ -d <domain2> ]..."
   echo "      [ -s <server_key_base_name> {default:selfca_server} ]"
   echo "      [ -ca <CA_key_base_name> {default:selfca_ca} ]"
   echo "      [ -cn <common_name> {default:Self CA for domain1...} ]"
   echo "      [ -o <organisation_name> {default:Self CA} ]"
   echo "      [ --overwrite ]"
   echo "      [ --days <days_to_expiry> {default:3650}]"
}

while [ $# -gt 0 ] ; do

   case "$1" in

      "-cn" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          common_name=$1
          ;;

      "-o" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          org=$1
          ;;

      "-ca" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          ca=$1
          ;;

      "-s" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          server=$1
          ;;

       "-d" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          domains="$domains $1"
          ;;

       "--days" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          days=$1
          ;;

       "--overwrite" )

          overwrite=1
          ;;

        * )

          usage
          exit 1
          ;;

   esac

   shift

done

if [ -z "$domains" ]; then
    usage
    exit 1
fi

if [ $overwrite -eq 0 ] ; then
    for file in $ca.key $ca.pem $server.key $server.cert ; do

        if [ -f $file ]; then
            echo $file already exists and overwrite is not set
            exit 2
        fi

    done
fi

if [ -z "$common_name" ]; then
    common_name="Self CA for${domains}"
fi

subject="/CN=${common_name}/O=${org}"

# 1 Generate the CA key

openssl genrsa -out $ca.key 2048

# 2 Generate the CA pem

openssl req -x509 -new -nodes -key $ca.key -sha256 -days $days -subj "$subject" -out $ca.pem

# 3 Generate the SERVER key

openssl genrsa -out $server.key 2048

# 4 Generate the SERVER CSR

openssl req -new -key $server.key -subj "$subject" -out $server.csr

# 5 Create the extensions file

extfile=$(mktemp)

cat > $extfile << EOF
authorityKeyIdentifier = keyid, issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

# 6 Add the domains to the extensions file

let entry=1
for domain in $domains ; do

    echo "DNS.${entry} = ${domain}" >> $extfile
    let entry++

done

# 7 Generate the SERVER cert

openssl x509 -req -in $server.csr -CA $ca.pem -CAkey $ca.key -CAcreateserial \
             -out $server.cert -days $days -sha256 -extfile $extfile
             
rm $extfile             

echo ================================================================================
echo $server.key is the server key to be used in the server
echo $server.cert is the server cert to be used in the server
echo $ca.pem is the CA authority cert to be imported into the browser, keychain etc
echo ================================================================================
echo For development purposes, $ca.key, $server.csr and $server.srl can be ignored

