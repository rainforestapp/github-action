#!/bin/bash

set -euo pipefail

# Show Action Version
echo "Using Rainforest GitHub Action v${RF_ACTION_VERSION}"

# Ensure results directory is there
mkdir -p results/rainforest

echo "::add-mask::${RF_TOKEN}"

# Define error helper
error () {
  echo "::error ::${1}"
  echo "error=${1}" >> "$GITHUB_OUTPUT"
  exit 1
}

# Validate token
if [ -z "${RF_TOKEN}" ] ; then
  error "Token not set"
fi

# Validate run_group_id
if ! echo "${RF_RUN_GROUP_ID}" | grep -Eq '^[0-9]+$' ; then
  error "run_group_id not a positive integer (${RF_RUN_GROUP_ID})"
fi

# Check for rerun
if [ -s .rainforest_run_id ] ; then
  RAINFOREST_RUN_ID=$(cat .rainforest_run_id)
  rm .rainforest_run_id
  echo "Rerunning Run ${RAINFOREST_RUN_ID}"

  RUN_COMMAND="rerun \"${RAINFOREST_RUN_ID}\" --skip-update --token \"${RF_TOKEN}\" --junit-file results/rainforest/junit.xml --save-run-id .rainforest_run_id"
else
  RAINFOREST_RUN_ID=""
  RUN_COMMAND="run --skip-update --token \"${RF_TOKEN}\" --run-group ${RF_RUN_GROUP_ID} --junit-file results/rainforest/junit.xml --save-run-id .rainforest_run_id"
fi

# Validate conflict
if [ -n "${RF_CONFLICT}" ] ; then
  case "${RF_CONFLICT}" in
    cancel) ;&
    cancel-all)
      RUN_COMMAND="${RUN_COMMAND} --conflict ${RF_CONFLICT}"
    ;;
    *)
      error "${RF_CONFLICT} not in (cancel cancel-all)"
    ;;
  esac
fi

# Set custom_url, or validate and set environment_id
if [ -z "${RAINFOREST_RUN_ID}" ] && [ -n "${RF_CUSTOM_URL}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --custom-url \"${RF_CUSTOM_URL}\""
  if [ -n "${RF_ENVIRONMENT_ID}" ] ; then
    echo "::warning title=Environment ID Ignored::You've set values for the mutually exclusive custom_url and environment_id parameters. Unset one of these to fix this warning."
  fi
elif [ -z "${RAINFOREST_RUN_ID}" ] && [ -n "${RF_ENVIRONMENT_ID}" ] ; then
  if echo "${RF_ENVIRONMENT_ID}" | grep -Eq '^[0-9]+$' ; then
    RUN_COMMAND="${RUN_COMMAND} --environment-id ${RF_ENVIRONMENT_ID}"
  else
    error "environment_id not a positive integer (${RF_ENVIRONMENT_ID})"
  fi
fi

# Validate execution_method / crowd
if [ -z "${RAINFOREST_RUN_ID}" ] ; then
  if [ -n "${RF_EXECUTION_METHOD}" ] ; then
    case "${RF_EXECUTION_METHOD}" in
      automation) ;&
      crowd) ;&
      automation_and_crowd) ;&
      on_premise)
        RUN_COMMAND="${RUN_COMMAND} --execution-method ${RF_EXECUTION_METHOD}"
      ;;
      *)
        error "${RF_EXECUTION_METHOD} not in (automation crowd automation_and_crowd on_premise)"
      ;;
    esac
  fi

  if [ -n "${RF_CROWD}" ] ; then
    if [ -n "${RF_EXECUTION_METHOD}" ] ; then
      error "Error: execution_method and crowd are mutually exclusive"
    fi

    case "${RF_CROWD}" in
      default) ;&
      automation) ;&
      automation_and_crowd) ;&
      on_premise_crowd)
        RUN_COMMAND="${RUN_COMMAND} --crowd ${RF_CROWD}"
      ;;
      *)
        error "${RF_CROWD} not in (default automation automation_and_crowd on_premise_crowd)"
      ;;
    esac
  fi
fi

# Validate automation_max_retries
if [ -n "${RF_AUTOMATION_MAX_RETRIES}" ] ; then
  if echo "${RF_AUTOMATION_MAX_RETRIES}" | grep -Eq '^[0-9]+$' ; then
    RUN_COMMAND="${RUN_COMMAND} --automation-max-retries ${RF_AUTOMATION_MAX_RETRIES}"
  else
    error "automation_max_retries not a positive integer (${RF_AUTOMATION_MAX_RETRIES})"
  fi
fi

# Set branch
if [ -n "${RF_BRANCH}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --branch \"${RF_BRANCH//\"/\\\"}\""
fi

# Set description
if [ -z "${RAINFOREST_RUN_ID}" ] && [ -n "${RF_DESCRIPTION}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --description \"${RF_DESCRIPTION//\"/\\\"}\""
elif [ -z "${RAINFOREST_RUN_ID}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --description \"${GITHUB_REPOSITORY} - ${GITHUB_REF_NAME} ${GITHUB_JOB} $(date -u +'%FT%TZ')\""
fi

# Set release
if [ -n "${RF_RELEASE}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --release \"${RF_RELEASE//\"/\\\"}\""
elif [ -z "${RAINFOREST_RUN_ID}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --release \"${GITHUB_SHA}\""
fi

# Set background
if [ -n "${RF_BACKGROUND}" ] ; then
  RUN_COMMAND="${RUN_COMMAND} --background"
fi

echo "command=${RUN_COMMAND}" >> "$GITHUB_OUTPUT"
