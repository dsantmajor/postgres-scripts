#!/bin/bash
# A script to create a user.

usage() {
	cat <<- EOF
		usage: $0 OPTIONS

		This script creates a user for a given postgres database.

		OPTIONS:
		   -h   Show this message
			   -n   Hostname (defaults to localhost
		   -p   Port (defaults to 5432)
		   -u   Username (defaults to postgres)
			   -d   Database name
		   -r   Role name
		   -s   Schema (defaults to public)
		   -w   password (defaults to changeme)

		EXAMPLE 1: ./create_readonly_user_pg.sh -n <hostname> -p <port> -u <Db owner> -r <rolename> -s <schema name> -d <DB name>
	EXAMPLE 2: ./create_readonly_user_pg.sh -n 127.0.0.1 -p 5432 -u dbuser -r readonly -s public -d dbname
	EXAMPLE 3: ./create_readonly_user_pg.sh -r readonly -d dbname -w password

	EOF
}



create_user() {
	local cmd=$1
	psql -h $HOST_NAME -p $PORT -U $USERNAME --no-psqlrc --no-align --tuples-only --record-separator=\0 --quiet \
		--echo-queries --command="$cmd" "$DB_NAME"
}



PASSWORD='changeme'
NEW_USER=''
HOST_NAME='localhost'
DB_NAME=''
ROLE=''
SCHEMA='public'
PORT='5432'
USERNAME=${OPTARG:-postgres}
while getopts "hd:u:r:s:n:p:w:" OPTION; do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		d)
			DB_NAME=$OPTARG
			;;
		u)
			USERNAME=$OPTARG
			;;
		r)
			ROLE=$OPTARG
			;;
		s)
			SCHEMA=$OPTARG
			;;
		n)
		  HOST_NAME=$OPTARG
		 	;;
		 p)
		 	PORT=$OPTARG
		 	;;
		 w)
		 	PASSWORD=$OPTARG
		 	;;
	esac
done

if [[ -z "$DB_NAME" ]] || [[ -z "$USERNAME" ]] || [[ -z "$ROLE" ]] || [[ -z "$HOST_NAME" ]] || [[ -z "$PORT" ]] | [[ -z "$PASSWORD" ]]; then
	usage
	exit 1
fi



# A function to draw a line to help highlight a message when you call this with an
# agrument example call_drawline "Don" the oputput will be as shown below
#    -------------
#    TASK < Don >
#    -------------
#
drawline () {
  declare line=""
  declare char="-"
  for (( i=0; i<len; ++i )); do
    line="${line}${char}"
  done
  printf "%s\n" "$line"
}

# no arguments? no output

call_drawline () {

  [[ ! $1 ]] && exit 0

  declare -i len="${#1} + 13"
  drawline len
  printf "< TASK [ %s ] >\n" "$1"
  drawline len

}

# call_drawline " The user : $ROLE will be granted READONLY privileges to DB  : $DB_NAME "

echo " "
echo " "
call_drawline "Creating ReadOnly User : $ROLE"

# echo " User    : $ROLE "
echo " Database: $DB_NAME "
echo " Hostname: $HOST_NAME "

echo "--------------------------------------------- "
echo " "
echo " "



exec_create_user () {
 create_user "CREATE USER $ROLE with PASSWORD '$PASSWORD';"
}

while true; do
		read -p "Do you wish to proceed with this TASK [Yes / No] ?" yn

    case $yn in
        [Yy]* ) exec_create_user; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
