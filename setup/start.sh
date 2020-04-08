#!/bin/sh

## Below are the steps to enable HTTPS with self singed certificates for Nexus
## Use Openssl to create pem file

 if [ ! -d /home/appuser/data/certificates ]; echo  "create certificate directory"; then mkdir /home/appuser/data/certificates; fi

echo "SSL implementation"
if [ ! -f /home/appuser/data/certificates/cer.pem ] || [ ! -f /home/appuser/data/certificates/key.pem ]
then
    echo "set initialstart variable to 1"
    HV_INITIALSTART=1
fi

if [ "$HV_INITIALSTART" == "1" ]
then

    echo "create a self signed certificate with a validity of 10 days"
    NX_SSLSUBJECT="/C=DE/ST=Bavarian/L=Ismaning/O=msg-systems/OU=Automotive/CN=$NX_SSLHOST.$NX_SSLDOMAIN"
    echo "...subject: $NX_SSLSUBJECT"
    openssl req -x509 -newkey rsa:4096 -keyout /home/appuser/data/certificates/key.pem -out /home/appuser/data/certificates/cer.pem -days 10 -nodes -subj "$NX_SSLSUBJECT"

    echo "check if both certificate and key file are present"
    if [ ! -f /home/appuser/data/certificates/cer.pem ] || [ ! -f /home/appuser/data/certificates/key.pem ]
    then
        echo "Either certificate or Key file is missing"
        exit 1
    fi

fi


openssl pkcs12 -export -in /home/appuser/data/certificates/cer.pem -inkey /home/appuser/data/certificates/key.pem -out /home/appuser/data/certificates/jetty.key -passout pass:password


keytool -importkeystore -noprompt -deststorepass password -destkeypass password -destkeystore /home/appuser/data/certificates/keystore.jks -srckeystore /home/appuser/data/certificates/jetty.key -srcstoretype PKCS12 -srcstorepass password

cp /home/appuser/data/certificates/keystore.jks /home/appuser/app/nexus-3.14.0-04/etc/ssl/

echo "Starting nexus"
/home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus run