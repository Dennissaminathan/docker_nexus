#!/bin/bash
echo "starting prepare.sh script..."

# TODO: Move this stuff completly to start.sh with a firststart-section. Have a look to keycloak as example

echo "intializing index value"
index=0

sed -i "s/#run_as_user=[\"][\"]/run_as_user=\"appuser\"/" /home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus.rc

## start Nexus process for the configuration

/home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus start

## Wait until nexus is started
sleep 120


## Stop Nexus
/home/appuser/app/nexus-$NEXUS_VERSION/bin/nexus stop

#sleep 10

## make configuration change in nexus.properties with HTTPS parameter and port for SSL.
sed \-e '/Jetty section/ s/^#*/#/' \-re '/# application-host=/s/^#//' \-e "/# Jetty section/a\\application-port-ssl=8443" \-i /home/appuser/app/sonatype-work/nexus3/etc/nexus.properties

sed \-e "s%$jetty-http.xml%$jetty-https.xml%g" \-e '/# nexus-args=/s/^#//' \-e'/# nexus-context-path=/s/^#//' \-i /home/appuser/app/sonatype-work/nexus3/etc/nexus.properties


##Softlink creation for blobstore backup
mv /home/appuser/app/sonatype-work /home/appuser/data/
ln -s /home/appuser/data/sonatype-work  /home/appuser/app/
