#!/bin/bash

cmd="ls /home/appuser/data/firststart.flg"
while ! docker exec -it 1f9dcf23c228 sh -c "${cmd}" > /dev/null 2>&1; do
        echo "firststart_finished.flg not available. Wait 15s for slow java junk and try again ..."
        sleep 10s
    done
old_pwd=$(docker exec -it 1f9dcf23c228 sh -c "cat /home/appuser/data/sonatype-work/nexus3/admin.password")
NEXUS_OLD_PWD=$(docker exec -it 1f9dcf23c228 sh -c  "cat /home/appuser/data/sonatype-work/nexus3/admin.password")

echo $NEXUS_OLD_PWD

  NEXUS_URL=https://localhost:8096
  #local NEXUS_OLD_PWD=$2
  NEXUS_NEW_PWD=admin123
  shift 3
  CURL_OPTS="$@"
  SCRIPT_NAME=change_admin_password
  echo $NEXUS_OLD_PWD
  read -r -d '' SCRIPT_JSON << EOF
{
  "name": "${SCRIPT_NAME}",
  "type": "groovy",
  "content": "security.securitySystem.changePassword('admin', args)"
}
EOF

  CHECK_SCRIPT_STATUS=`curl ${CURL_OPTS} -s -o /dev/null -I -w "%{http_code}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_URL}/service/siesta/rest/v1/script/${SCRIPT_NAME}"`

echo $SCRIPT_JSON


echo $CHECK_SCRIPT_STATUS
echo $CURL_OPTS

  if [ "${CHECK_SCRIPT_STATUS}" == "404" ];then
    echo "> ${SCRIPT_NAME} is not found (${CHECK_SCRIPT_STATUS})"
    echo "> creating script (${SCRIPT_NAME}) ..."
    curl ${CURL_OPTS} -H "Accept: application/json" -H "Content-Type: application/json" -d "${SCRIPT_JSON}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_URL}/service/siesta/rest/v1/script/" --insecure
  elif [ "${CHECK_SCRIPT_STATUS}" == "401" ];then
    echo "> Unauthorized (${CHECK_SCRIPT_STATUS})"
    return
  else
    echo "> ${SCRIPT_NAME} is found (${CHECK_SCRIPT_STATUS})"
    echo "> updating script (${SCRIPT_NAME}) ..."
    curl ${CURL_OPTS} -XPUT -H "Accept: application/json" -H "Content-Type: application/json" -d "${SCRIPT_JSON}" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_URL}/service/siesta/rest/v1/script/${SCRIPT_NAME}" --insecure
  fi


  echo "> updating password ..."
  CHECK_RUN_STATUS=`curl ${CURL_OPTS} -s -o /dev/null -w "%{http_code}" -H "Content-Type: text/plain" -u "admin:${NEXUS_OLD_PWD}" "${NEXUS_URL}/service/siesta/rest/v1/script/${SCRIPT_NAME}/run" -d "${NEXUS_NEW_PWD}" --insecure`

  if [ "${CHECK_RUN_STATUS}" == "200" ];then
    echo "> succeeded!"
  else
    echo "> failed! (${CHECK_RUN_STATUS})"
  fi

