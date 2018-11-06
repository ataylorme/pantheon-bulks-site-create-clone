#!/bin/bash

# Our input file is the first argument passed to the script
# but give me the option to specificy the csv after beginning the script

if [ -z "$1" ]; then
    echo -n "Please specify a csv file.: " && read INPUT
else
    INPUT=$1
fi

if [[ ! -f $INPUT ]]; then
    echo -e "The specified csv file $1 does not exist.\n"
    exit 1;
fi

echo -e "Welcome to the Pantheon bulk site creation script\n\n"

# Site prefix
echo -e "What project name would you like to use?"
echo -e "e.g. My Cool Training\n"
read -p 'Project Name: ' PROJECT_NAME
PROJECT_SLUG=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')
PROJECT_SLUG=$(echo "$PROJECT_SLUG" | tr '[:space:]' '-')
PROJECT_SLUG=${PROJECT_SLUG%-}
echo -e "Generated a slug of $PROJECT_SLUG based on the project name $PROJECT_NAME\n\n"

# Source site
echo -e "What is the UUID of the site you would like to clone from (source)?"
echo -e "Leave blank for fresh sites.\n"
read -p 'Source site UUID: ' SOURCE_UUID
if [ -z $SOURCE_UUID ]; then
    echo -e "No source UUID given, will create fresh sites\n"
    terminus upstream:list --fields=label,machine_name,framework
    echo -e "What upstream would you like to use?"
    echo -e "Please enter the machine name.\n"
    read -p 'Upstream: ' UPSTREAM
    if [ -z $UPSTREAM ]; then
        echo -e "No upstream given, aborting"
        exit 1
    fi
else
    echo -e "What environment would you like to clone from (source)?"
    echo -e "Leave blank for dev.\n"
    read -p 'Source Environment: ' SOURCE_ENVIRONMENT
    if [ -z $SOURCE_ENVIRONMENT ]; then
        echo -e "No source environment given, using dev"
        SOURCE_ENVIRONMENT='dev'
    fi
    echo -e "Using the $SOURCE_ENVIRONMENT of the site $SOURCE_UUID to clone from\n\n"
    UPSTREAM="$(terminus site:info $SOURCE_UUID --field=upstream | cut -f1 -d':')"
fi

# Org
echo -e "What is the UUID of the organization you would like new sites to be added to?"
echo -e "Leave blank for no organization.\n"
read -p 'Organization UUID: ' ORG_UUID
if [ -z $ORG_UUID ]; then
    echo -e "No organization UUID given, skipping adding new sites to an organization\n\n"
else
    echo -e "New sites will be added to the organization $ORG_UUID\n\n"
fi

DESTINATION_ENVIRONMENT='dev'

echo -e "Beginning site creation based on the $INPUT csv file.\n\n"

# Stash the existing Internal File Sperator token, which is usually whitespace
OLDIFS=$IFS

# Set the Internal File Sperator token to a comma for parsing CSV
IFS=,

# while in this loop, parce the columns in the CSV as these variables
#	FIRST_NAME is the new user's first name
#	LAST_NAME is the new user's last name
# 	PANTHEON_EMAIL is the email address for the end users' Pantheon account
#   DESTINATION_ENVIRONMENT is the environment to clone code, db and files to
while read  FIRST_NAME LAST_NAME PANTHEON_EMAIL
do

    # Stash USER_SLUG based on first initial last name
    FIRST_INITIAL="$(echo $FIRST_NAME | head -c 1)"
    USER_SLUG="$FIRST_INITIAL$LAST_NAME"

    # Generate DESTINATION_NAME based on the site prefix and user slug
    DESTINATION_NAME="$USER_SLUG-$PROJECT_SLUG"
    DESTINATION_ENVIRONMENT='dev'

    # Let the world know we are kicking off site creation
    echo -e "Kicking off site generation for $FIRST_NAME $LAST_NAME."
    echo -e "Using the slug $USER_SLUG and site name $DESTINATION_NAME\n\n"

    # Create a new site on Pantheon
    if [ -z $ORG_UUID ]; then
        # No org
        terminus site:create ${DESTINATION_NAME} ${DESTINATION_NAME} ${UPSTREAM}
    else
        # With org
        terminus site:create --org=${ORG_UUID} ${DESTINATION_NAME} ${DESTINATION_NAME} ${UPSTREAM}
    fi

    FRAMEWORK=$(terminus site:info ${DESTINATION_NAME} --field=framework)

    # Not cloning
    #if [ -z $SOURCE_UUID ]; then
        #if [ $FRAMEWORK == 'wordpress' ]; then
        #    install_wordpress
        #fi
    #fi

    echo -e "\nUpdating Terminus site list, this may take a while...\n\n"
    terminus site:list 2>&1 >/dev/null

    # Get UUID of new site
    DESTINATION_UUID=$(terminus site:lookup ${DESTINATION_NAME} --field=id)

	# Clone demo site code, database and files to new site
    if [ ! -z $SOURCE_UUID ]; then
        SOURCE="$SOURCE_UUID.$SOURCE_ENVIRONMENT"
        DESTINATION="$DESTINATION_UUID.$DESTINATION_ENVIRONMENT"
        echo -e "Cloning code, database and files from the $SOURCE to $DESTINATION. This may take a while...\n\n"
        terminus site:clone $SOURCE $DESTINATION --yes
    fi
    
	# Add a tag to the site for the project
    if [ ! -z $ORG_UUID ]; then
	echo -e "Adding the tag $PROJECT_SLUG to the $DESTINATION_NAME site...\n"
	terminus tag:add $DESTINATION_NAME ${ORG_UUID} $PROJECT_SLUG
    fi

	# Add the user to the Pantheon team
	echo -e "Adding the Pantheon user $PANTHEON_EMAIL to the $DESTINATION_NAME site...\n"
	terminus site:team:add ${DESTINATION_UUID} ${PANTHEON_EMAIL}
	
       # Make the user the owner of the site
       # echo -e "Making the Pantheon user $PANTHEON_EMAIL the owner of the $DESTINATION_NAME site...\n"
       # terminus owner:set $DESTINATION_NAME ${PANTHEON_EMAIL}

# if we are not at the end of the file, we are not done, loop again
done < $INPUT

echo -e "All sites have been created. Cheers!\n"

exit 0

# Restore the default Internal File Sperator token
IFS=$OLDIFS
