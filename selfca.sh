#!/bin/bash

set -e

ca=my_ca
server=my_server
domains=""
main_domain=""
overwrite=0
days=3650

usage()
{
   echo "Usage:"
   echo "   $0 ( --domain | -d ) <domain> [ ( -domain | -d ) <domain2> ]..."
   echo "      [ ( --server | -s ) <server_key_base_name> {default:my_server} ]"
   echo "      [ ( --ca | -c ) <CA_key_base_name> {default:my_ca}]"
   echo "      [ ( --overwrite | -o)"
   echo "      [ --days <days_to_expiry> {default:3650}]"
}

while [ $# -gt 0 ] ; do

   case "$1" in

      "--ca" | "-c" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          ca=$1
          ;;

      "--server" | "-s" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          server=$1
          ;;

       "--domain" | "-d" )

          shift
          if [ $# -eq 0 ]; then
             usage
             exit 1
          fi
          if [ -z "$main_domain" ]; then
              main_domain="$1"
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

       "--overwrite" | "-o" )

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
    for file in $ca.key $ca.pem $server.key $server.ext $server.cert ; do

        if [ -f $file ]; then
            echo $file already exists and overwrite is not set
            exit 2
        fi

    done
fi

# 1 make the CA key

openssl genrsa -out $ca.key 2048

# 2 make the CA pem

openssl req -x509 -new -nodes -key $ca.key -sha256 -days $days -subj "/CN=${main_domain}" -out $ca.pem

# 3 make the SERVER key

openssl genrsa -out $server.key 2048

# 4 make the SERVER CSR

openssl req -new -key $server.key -subj "/CN=${main_domain}" -out $server.csr

# 5 make the SERVER extensions file

cat > $server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

let entry=1
for domain in $domains ; do

    echo "DNS.${entry} = ${domain}" >> $server.ext
    let entry++
done

# 5 make the SERVER cert

openssl x509 -req -in $server.csr -CA $ca.pem -CAkey $ca.key -CAcreateserial \
             -out $server.cert -days $days -sha256 -extfile $server.ext

echo $server.key is the server key
echo $server.cert is the server cert
echo $ca.pem is the CA authority to be used in the browser, etc

