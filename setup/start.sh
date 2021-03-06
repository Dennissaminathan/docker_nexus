#!/bin/sh

## Below are the steps to enable HTTPS with self singed certificates for Nexus
## Use Openssl to create pem file

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
    ##Change default key store password to custom
    sed "s%password%${NX_CERTPWD}%g" -i /home/appuser/app/nexus-$NEXUS_VERSION/etc/jetty/jetty-https.xml

    ##Softlink creation for blobstore backup
    mv /home/appuser/app/sonatype-work /home/appuser/data/
    ln -s /home/appuser/data/sonatype-work  /home/appuser/app/


    echo "initialstart variable is set to $INITIALSTART"
    ##Creation of certificates
    /home/appuser/app/helper/createcerts.sh



    echo "Create nexus certificate"
    openssl pkcs12 -export -in /home/appuser/data/certificates/cer.pem -inkey /home/appuser/data/certificates/key.pem -out /home/appuser/data/certificates/nexus.key -passout pass:${NX_CERTPWD}

    keytool -importkeystore -noprompt -deststorepass ${NX_CERTPWD} -destkeypass ${NX_CERTPWD} -destkeystore /home/appuser/data/certificates/nexus_keystore.jks -srckeystore /home/appuser/data/certificates/nexus.key -srcstoretype PKCS12 -srcstorepass ${NX_CERTPWD}

    ln -s /home/appuser/data/certificates/nexus_keystore.jks  /home/appuser/app/nexus-$NEXUS_VERSION/etc/ssl/keystore.jks
     sleep 10 
     echo `date +%Y-%m-%d_%H:%M:%S_%z` > /home/appuser/data/firststart_finished.flg
fi 
echo "Starting nexus"
/home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus run
