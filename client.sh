#!/bin/bash

if [ $# -ne 1  ]; then

	echo "ERROR: Malformed instruction. This command requires at least one parameter."

	echo -e "\n\tUse example: $0 127.0.0.1"

	echo " "

	exit 1
fi

PORT=7777

IP_SERVER=$1

FILE="saludo.ogg"

IP_CLIENT=`ip a | grep "inet " | grep global | cut -d " " -f 6 | cut -d "/" -f 1`

echo "LSTP Client (Lechuga Speaker Transfer Protocol)"

echo "1. SEND HEADER"

echo "LSTP_1.1 $IP_CLIENT" | nc $IP_SERVER $PORT

echo "2. LISTEN OK/KO_HEADER"

DATA=`nc -l $PORT`

echo "6. CHECK OK/KO_HEADER"

if [ "$DATA" != "OK/KO_HEADER"  ]; then

	echo "ERROR 1: Header not sent correctly. $DATA"

	exit 1
fi

#text2wave client/lechuga1.lechu -o client/lechuga1.wav

#ffmpeg -i client/lechuga1.wav client/lechuga1.ogg

echo "7. SEND FILE_NAME"

echo "FILE_NAME $FILE" | nc $IP_SERVER $PORT

echo "8. LISTEN PREFIX_OK/KO"

DATA=`nc -l $PORT`

if [ "$DATA" != "OK/KO_FILE_NAME" ]; then
	
	echo "ERROR 2: Filename not set correctly. $DATA"

	exit 2

fi

echo "12. SEND FILE_DATA"

cat "client/$FILE" | nc $IP_SERVER $PORT

echo "13. LISTEN OK/KO_FILE_DATA"

DATA=`nc -l $PORT`

echo "16. CHECK OK/KO_FILE_DATA"

if [ "$DATA" != "OK/KO_FILE_DATA" ]; then

	echo "ERROR 3: No data in sent file. $DATA"

	exit 3

fi

echo "17. SEND MD5"

MD5=`cat "client/$FILE" | md5sum | cut -d " " -f 1`

echo "$MD5" | nc $IP_SERVER $PORT

echo "18. LISTEN OK/KO_MD5"

DATA=`nc -l $PORT`

echo "21. CHECK OK/KO_MD5"

if [ $DATA != "OK/KO_FILE_DATA_MD5" ]; then
	
	echo "ERROR 4: MD5 not coincident."

fi

exit 0
