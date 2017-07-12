#!/bin/bash
# A script to create a user and grant read-only privileges

usage() {
	cat <<- EOF
		usage: $0 OPTIONS


		example: ./create_readonly_user_pg.sh -n 127.0.0.1 -p 5432 -u dbuser -r readonly -s public -d dbname
		example: ./create_readonly_user_pg.sh -n <hostname> -p <port> -u <Db owner> -r <rolename> -s <schema name> -d <DB name>


		This script grants read-only privileges to a specified role on all tables, views
		and sequences in a database schema and sets them as default.

		OPTIONS:
		   -h   Show this message
			   -n   Hostname
		   -p   Port (defaults to 5432)
		   -u   Username (defaults to postgres)
			   -d   Database name
		   -r   Role name
		   -s   Schema (defaults to public)

	EOF
}

pgexec() {
	local cmd=$1
	psql -h $HOST_NAME -p $PORT -U $USERNAME --no-psqlrc --no-align --tuples-only --record-separator=\0 --quiet \
		--echo-queries --command="$cmd" "$DB_NAME"
}

HOST_NAME='localhost'
DB_NAME=''
ROLE=''
SCHEMA='public'
PORT='5432'
USERNAME=${OPTARG:-postgres}
while getopts "hd:u:r:s:n:p:" OPTION; do
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
	esac
done

if [[ -z "$DB_NAME" ]] || [[ -z "$USERNAME" ]] || [[ -z "$ROLE" ]] || [[ -z "$HOST_NAME" ]] || [[ -z "$PORT" ]]; then
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
call_drawline "Granting ReadOnly privileges"

echo " User    : $ROLE "
echo " DataBase: $DB_NAME "
echo " Schema  : $SCHEMA "

echo "--------------------------------------------- "
echo " "
echo " "

grant_readonly_privileges  () {
pgexec "GRANT CONNECT ON DATABASE ${DB_NAME} TO ${ROLE};
GRANT USAGE ON SCHEMA ${SCHEMA} TO ${ROLE};
GRANT SELECT ON ALL TABLES IN SCHEMA ${SCHEMA} TO ${ROLE};
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ${SCHEMA} TO ${ROLE};
ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA} GRANT SELECT ON TABLES TO ${ROLE};
ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA} GRANT SELECT ON SEQUENCES TO ${ROLE};"
}

while true; do
		read -p "Do you wish to proceed with this TASK [Yes / No] ?" yn

    case $yn in
        [Yy]* ) grant_readonly_privileges; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done



# Uncomment to also grant privileges on all functions/procedures in the schema.
# It's usually NOT what you want - functions can modify data!
#pgexec "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ${SCHEMA} TO ${ROLE};
#ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA} GRANT EXECUTE ON FUNCTIONS TO ${ROLE};"
