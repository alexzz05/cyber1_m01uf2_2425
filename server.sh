#!/bin/bash

PORT=7777
IP_CLIENT="localhost"
WORKING_DIR="server"

echo "LSTP Server (Lechuga Speaker Transfer Protocol)"

echo "0.LISTEN"

DATA=`nc -l $PORT`

echo "3. CHECK HEADER"

HEADER=`echo "$DATA" | cut -d " " -f 1`

if [ "$HEADER" != "LSTP_1" ]
then
        echo "ERROR1: Header mal formado $DATA"

        echo "KO_HEADER" | nc $IP_CLIENT $PORT

        exit 1
fi

IP_CLIENT=`echo "$DATA" | cut -d " " -f 2`

echo "4. SEND OK/KO_HEADER"

echo "OK_HEADER" | nc $IP_CLIENT $PORT

echo "5.1 LISTEN NUM_FILES"

DATA=`nc -l $PORT`

echo "5.2 CHECK NUM_FILES"

PREFIX=`echo $DATA | cut -d " " -f 1`

if [ "$PREFIX" != "NUM_FILES" ]
then
        echo "ERROR: PREFIX incorrecto"

        echo "KO_PREFIX" | nc $IP_CLIENT $PORT

        exit
fi

NUM_FILES=`echo $DATA | cut -d " " -f 2`

NUM_FILES_CHECK=`echo "$NUM_FILES" | grep -E "^-?[0-9]+$"`

if [ "$NUM_FILES_CHECK" == "" ]
then
        echo "ERROR 22: Número de archivos incorrecto (no es un número)"

        echo "KO_NUM_FILES" | nc $IP_CLIENT $PORT

        exit 22
fi
if [ "$NUM_FILES" -lt 1 ]
then
        echo "ERROR 22: NUM_FILES incorrecto"

        echo "KO_NUM_FILE" | nc $IP_CLIENT $PORT

        exit 22
fi

echo "OK_NUM_FILES" | nc $IP_CLIENT $PORT

for NUM in `seq $NUM_FILES`
do
        echo "5.X LISTEN FILE_NAME $NUM"

        DATA=`nc -l $PORT`

        echo "9. CHECK FILE_NAME"

        PREFIX=`echo $DATA | cut -d " " -f 1`

        if [ "$PREFIX" != "FILE_NAME" ]
        then
                echo "ERROR 2: FILE_NAME incorrecto"

                echo "KO_FILE_NAME" | nc $IP_CLIENT $PORT

                exit 3
        fi

        FILE_NAME=`echo $DATA | cut -d " " -f 2`

        echo "10. SEND OK/KO_FILE_NAME"

        echo "OK_FILE_NAME" | nc $IP_CLIENT $PORT

        echo "11. LISTEN FILE DATA"

        nc -l $PORT > $WORKING_DIR/$FILE_NAME

        echo "14. SEND OK/KO_FILEDATA"

        DATA=`cat $WORKING_DIR/$FILE_NAME | wc -c` 

	if [ $DATA -eq 0 ]
        then
                echo "ERROR 3: Datos mal formados (vacíos)"

                echo "KO_FILE_DATA" | nc $IP_CLIENT $PORT

                exit 4
        fi	
	
	echo "OK_FILE_DATA" | nc $IP_CLIENT $PORT

        echo "15. LISTEN FILE_DATA_MD5"
        
        DATA=`nc -l $PORT`

        echo "18. CHECK FILE_DATA_MD5"

        PREFIX=`echo $DATA | cut -d " " -f 1`

        if [ "$PREFIX" != "FILE_DATA_MD5" ]
        then
                echo "ERROR 4: FILE_DATA_MD5 incorrecto"

                echo "KO_FILE_DATA_MD5" | nc $IP_CLIENT $PORT

                exit 4
        fi

        RECEIVED_MD5=`echo $DATA | cut -d " " -f 2`

        LOCAL_MD5=`md5sum $WORKING_DIR/$FILE_NAME | cut -d " " -f 1`

        if [ "$RECEIVED_MD5" != "$LOCAL_MD5" ]
        then
                echo "ERROR 5: HASH enviado y local distintos"

                echo "KO_FILE_DATA_MD5" | nc $IP_CLIENT $PORT

                exit 6
        fi
        echo "19. SEND_OK/KO_FILE_DATA_MD5"

        echo "OK_FILE_DATA_MD5" | nc $IP_CLIENT $PORT

done

echo "FIN"

exit 0
