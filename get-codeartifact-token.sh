#!/bin/bash

if [[ -z "${CODEARTIFACT_DOMAIN}" ]]; then
  CODEARTIFACT_DOMAIN="tuned"
fi

if [[ -z "${CODEARTIFACT_REGION}" ]]; then
  CODEARTIFACT_REGION="us-east-1"
fi

if [[ -z "${CODEARTIFACT_DOMAIN_OWNER}" ]]; then
  CODEARTIFACT_DOMAIN_OWNER="703155998277"
fi

if ! AWS_VERSION="$(aws --version 2> /dev/null)"; then
  echo >&2 "Could not find AWS CLI binary"
  exit 1
fi

if ! aws codeartifact help > /dev/null 2>&1; then
  echo >&2 "Your AWS CLI version (${AWS_VERSION}) does not support CodeArtifact"
  echo >&2 "See https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html for more information"
  exit 1
fi

if [[ ! -z "${TUNED_NO_SSO}" ]]; then
  PROFILE_TOGGLE=""
  CLI_AWS_PROFILE=""
else
  if [[ -z "${CLI_AWS_PROFILE}" ]]; then
    CLI_AWS_PROFILE="tuned-ss"
  fi

  if ! aws configure list-profiles | grep "${CLI_AWS_PROFILE}" > /dev/null; then
    echo >&2 "Unknown profile: ${CLI_AWS_PROFILE}"
    echo >&2 "See https://www.notion.so/tuned/Configuring-AWS-CLI-for-SSO-d41ff953a32e4c2982e01be092d72283 for more information"
    exit 1
  fi

  if ! aws sts get-caller-identity --profile ${CLI_AWS_PROFILE} > /dev/null 2>&1; then
    echo >&2 "Could not get caller identity for profile ${CLI_AWS_PROFILE}, starting SSO login"
    if ! aws sso login --profile ${CLI_AWS_PROFILE}; then
      echo >&2 "Unable to complete SSO login"
      exit 1
    fi
  fi

  echo >&2 "Using credentials from profile ${CLI_AWS_PROFILE}"
  PROFILE_TOGGLE="--profile"
fi

if ! CODEARTIFACT_TOKEN="$(aws codeartifact get-authorization-token --domain "${CODEARTIFACT_DOMAIN}" --domain-owner "${CODEARTIFACT_DOMAIN_OWNER}" --query authorizationToken --output text --region "${CODEARTIFACT_REGION}" ${PROFILE_TOGGLE} ${CLI_AWS_PROFILE})"; then
  echo >&2 "Could not get CodeArtifact token"
  exit 1
else
  echo "${CODEARTIFACT_TOKEN}"
fi

