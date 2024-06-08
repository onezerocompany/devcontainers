#!/bin/bash

DATASTORE_HOST=${DATASTORE_HOST:-"postgresql://postgres:5432?sslmode=disable"}

echo "Generating config"

cat > .firebaserc <<EOF
{
  "dataconnectEmulatorConfig": {
    "postgres": {
      "localConnectionString": "${DATASTORE_HOST}"
    }
  }
}
EOF

UI_PORT=${UI_PORT:-"5000"}
AUTH_PORT=${AUTH_PORT:-"5001"}
DATACONNECT_PORT=${DATACONNECT_PORT:-"5002"}
FIRESTORE_PORT=${FIRESTORE_PORT:-"5003"}
DATABASE_PORT=${DATABASE_PORT:-"5004"}
STORAGE_PORT=${STORAGE_PORT:-"5005"}
HOSTING_PORT=${HOSTING_PORT:-"5006"}
FUNCTIONS_PORT=${FUNCTIONS_PORT:-"5007"}
PUBSUB_PORT=${PUBSUB_PORT:-"5008"}
EVENTARC_PORT=${EVENTARC_PORT:-"5009"}

echo "Generating firebase.json file"
cat > firebase.json <<EOF
{
  "emulators": {
    "ui": {
      "enabled": true,
      "port": ${UI_PORT}
    },
    "auth": {
      "port": ${AUTH_PORT}
    },
    "dataconnect": {
      "port": ${DATACONNECT_PORT}
    },
    "firestore": {
      "port": ${FIRESTORE_PORT}
    },
    "database": {
      "port": ${DATABASE_PORT}
    },
    "storage": {
      "port": ${STORAGE_PORT}
    },
    "hosting": {
      "port": ${HOSTING_PORT}
    },
    "functions": {
      "port": ${FUNCTIONS_PORT}
    },
    "pubsub": {
      "port": ${PUBSUB_PORT}
    },
    "eventarc": {
      "port": ${EVENTARC_PORT}
    },
    "singleProjectMode": true
  }
}
EOF

COMMAND="firebase emulators:start --import=/data --export-on-exit"

INSPECT_FUNCTIONS=${INSPECT_FUNCTIONS:-"false"}
if [ "$INSPECT_FUNCTIONS" = "true" ]; then
  COMMAND="$COMMAND --inspect-functions"
fi

ONLY="functions,firestore,database,hosting,pubsub,storage,eventarc"
PROJECT_ID=${PROJECT_ID:-"default"}
if [ "$PROJECT_ID" != "default" ]; then
  ONLY="$ONLY,auth"
  COMMAND="$COMMAND --project $PROJECT_ID"
fi

ONLY=${ONLY:-"functions,hosting,ui,auth,dataconnect,firestore,database,storage,pubsub,eventarc"}

echo "Starting emulators: $COMMAND"

exec $COMMAND
