#!/bin/bash

# Get the project ID
PROJECT_ID=$(gcloud config get-value project)

# Get all services
SERVICES=$(gcloud app services list --project $PROJECT_ID --format 'value(id)' | grep -v default)

for SERVICE_ID in $SERVICES
do
  echo 
  echo "Service: $SERVICE_ID"

  # Get the latest version based on time of creation with 100% traffic
  LATEST_VERSION=$(gcloud app versions list --project $PROJECT_ID --service $SERVICE_ID --filter="traffic_split=1" --sort-by '~creation_time' --format 'value(id)' --limit 1)

  # If there is no version with 100% traffic, skip to the next service
  if [[ -z "$LATEST_VERSION" ]]; then
    echo
    echo "No version with 100% traffic for service $SERVICE_ID"
    continue
  fi

  # Print the ID of the latest version
  echo
  echo "Latest Version: $LATEST_VERSION"

  echo
  echo "Old Versions:"
  # List all versions with 0% traffic that are not the latest version
  OLD_VERSIONS=$(gcloud app versions list --project $PROJECT_ID --service $SERVICE_ID --filter="traffic_split=0 AND id != $LATEST_VERSION" --format="value(id)")

  # Check if there are old versions
  if [[ -z "$OLD_VERSIONS" ]]; then
    echo "No old versions found"
  else
    # Print the IDs of the old versions line by line
    for OLD_VERSION in $OLD_VERSIONS
    do
      echo $OLD_VERSION
    done
  fi

  # Stop the old versions and print the IDs of the stopped versions
  for OLD_VERSION in $OLD_VERSIONS
  do
    echo "Stopping version: $OLD_VERSION"
    gcloud app versions stop --project $PROJECT_ID --service $SERVICE_ID $OLD_VERSION --quiet
  done

  # Add two line spaces
  echo
  echo
done
