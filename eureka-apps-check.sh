#!/bin/bash

#THIS IS NOT SUPPOSED TO HAVE SOME PRODUCTION PURPOSE
#IT IS MORE TO VALIDATE THAT REGISTRATION IS SUCCESFULL

CONNECTION=$1                                                       # CONNECTION ADDRESS E.G. 192.168.99.100:8761
RESOURCE=$2                                                         # RESOURCE NAME E.G. supadupaservice
TRY_LIMIT=${3:-20}                                                  # LIMIT OF TRIES
TRY_COUNTER=0                                                       # TMP VAR THAT HOLDS LOOP COUNTER

REGISTRY_APPS_PATH=${REGISTRY_APPS_PATH:="/eureka/apps"}            # PATH WHERE WE CAN FIND APPS
ALIVE_STATUS="UP"                                                   # DEFAULT STATUS "ALIVE"
SLEEP=2                                                             # PAUSE BETWEEN LOOP ITERATIONS (SECONDS)

echo "======================================="
echo "CHECKING $RESOURCE SERVICE REGISTRATION"
echo "======================================="

while ([ "$HTTP_STATUS" != "200" ] && [ "$SERVICE_STATUS" != "$ALIVE_STATUS" ] && [ $TRY_COUNTER -lt "$TRY_LIMIT" ] )
do

	echo "GET http://$CONNECTION$REGISTRY_APPS_PATH/$RESOURCE : TRY $TRY_COUNTER"

	# store the whole response with the status at the and
	HTTP_RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}"  http://$CONNECTION$REGISTRY_APPS_PATH/$RESOURCE)

    # extract the body
    HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
    echo $HTTP_BODY > "eureka_$RESOURCE""_response_body".xml

    # extract the status code
    HTTP_CODE=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    # print status code
    echo "RESPONSE CODE : $HTTP_CODE"

    # extract the service status
    SERVICE_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -n 's:.*<status>\(.*\)</status>.*:\1:p')

    # print service status if exist
    if [ -n "$SERVICE_STATUS" ]; then
        echo "SERVICE STATUS : $SERVICE_STATUS";
    fi

    TRY_COUNTER=`expr $TRY_COUNTER + 1`
    sleep ${SLEEP}

done


JOKE=$(curl --silent http://api.icndb.com/jokes/random | sed -e 's/^.*"joke": "\([^"]*\)".*$/\1/')


if ([ "$HTTP_CODE" == "200" ] && [ "$SERVICE_STATUS" == "$ALIVE_STATUS" ] ); then
    echo "SCRIPT STATUS : PASSED"
    echo "JOKE OF THE DAY : $JOKE"
    exit 0
else
    echo "RESOURCE IS NOT AVAILABLE AT $CONNECTION/$REGISTRY_APPS_PATH/$RESOURCE"
    echo "OR IT'S HEALTH IS NOT $ALIVE_STATUS"
    echo "WAIT TIME EXCEEDED WHILE DOING $TRY_LIMIT TRIES"
    echo "SCRIPT STATUS : EPIC FAIL"
    echo "JOKE OF THE DAY : $JOKE"
    exit 1
fi