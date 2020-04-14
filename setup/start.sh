#!/bin/sh

## Below are the steps to enable HTTPS with self singed certificates for Nexus
## Use Openssl to create pem file
if [ ! -d /home/appuser/data/certificates ]; echo  "create certificate directory"; then mkdir /home/appuser/data/certificates; fi

INITIALSTART=0

# set initstart variable
if [ ! -f /home/appuser/data/firststart.flg ]
then
    echo "first start, set initialstart variable to 1"
    INITIALSTART=1
    echo `date +%Y-%m-%d_%H:%M:%S_%z` > /home/appuser/data/firststart.flg
else
        echo "It's not the first start, skip first start section"
fi

echo "Check if its initial start"
if [ "$INITIALSTART" == "1" ]
then
    echo "start nexus in background"
    echo "intializing index value"
    index=0

    sed -i "s/#run_as_user=[\"][\"]/run_as_user=\"appuser\"/" /home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus.rc
    echo "starting nexus"
    /home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus start &
    sleep 120
    ps -ef | grep 'java' | grep -v grep | awk '{print $1 }' | xargs kill -9
    sleep 10
    sed \-e '/Jetty section/ s/^#*/#/' \-re '/# application-host=/s/^#//' \-e "/# Jetty section/a\\application-port-ssl=8443" \-i /home/appuser/app/sonatype-work/nexus3/etc/nexus.properties

sed \-e "s%$jetty-http.xml%$jetty-https.xml%g" \-e '/# nexus-args=/s/^#//' \-e'/# nexus-context-path=/s/^#//' \-i /home/appuser/app/sonatype-work/nexus3/etc/nexus.properties


##Softlink creation for blobstore backup
mv /home/appuser/app/sonatype-work /home/appuser/data/
ln -s /home/appuser/data/sonatype-work  /home/appuser/app/


     echo "initialstart variable is set to $INITIALSTART"
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