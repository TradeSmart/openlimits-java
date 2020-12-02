#!/bin/bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
ROOT_DIR="$SCRIPT_DIR"

if [[ -z "${CODEARTIFACT_AUTH_TOKEN}" ]]; then
  export CODEARTIFACT_AUTH_TOKEN="$(${SCRIPT_DIR}/get-codeartifact-token.sh)"
fi

if [[ -z "${ARTIFACT_VERSION}" ]]; then
  ARTIFACT_VERSION="$(cat "$ROOT_DIR/CLIENT_ARTIFACT_VERSION")"
fi

if [[ -z "${CODEARTIFACT_DOMAIN}" ]]; then
  CODEARTIFACT_DOMAIN='tuned'
fi

if [[ -z "${CODEARTIFACT_DOMAIN_OWNER}" ]]; then
  CODEARTIFACT_DOMAIN_OWNER='703155998277'
fi

if [[ -z "${CODEARTIFACT_REPO}" ]]; then
  CODEARTIFACT_REPO='internal-libraries'
fi

ARTIFACT_GROUP='com.tuned'
ARTIFACT_ID='openlimits-java'
JAR_NAME="$ARTIFACT_ID-$ARTIFACT_VERSION.jar"
JAR_PATH="$ROOT_DIR/build/libs/"

CODEARTIFACT_ROOT="https://$CODEARTIFACT_DOMAIN-$CODEARTIFACT_DOMAIN_OWNER.d.codeartifact.us-east-1.amazonaws.com/maven/$CODEARTIFACT_REPO"

if ! mvn deploy:deploy-file -X \
  -s "$SCRIPT_DIR/mvn-settings.xml" \
  -DgroupId=$ARTIFACT_GROUP \
  -DartifactId=$ARTIFACT_ID \
  -Dversion="$ARTIFACT_VERSION" \
  -Dfile="$JAR_PATH$JAR_NAME" \
  -Dpackaging=jar \
  -DrepositoryId=codeartifact \
  -Durl=$CODEARTIFACT_ROOT;
then
  echo >&2 "Unable to deploy $JAR_PATH$JAR_NAME to $CODEARTIFACT_ROOT"
  exit 1
fi