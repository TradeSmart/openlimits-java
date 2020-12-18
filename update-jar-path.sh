#!/bin/bash

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

if [[ -z "${ARTIFACT_VERSION}" ]]; then
  ARTIFACT_VERSION="$(cat "CLIENT_ARTIFACT_VERSION")"
fi

if ! realpath / > /dev/null 2>&1; then
    echo >&2 "realpath not installed. Are you on MacOS? run: brew install coreutils"
    exit 1
fi

JAR_PATH=$(realpath "$SCRIPT_DIR/build/libs/openlimits-java-$ARTIFACT_VERSION.jar")

if [[ -z "${GRADLE_DIR}" ]]; then
  GRADLE_DIR="${HOME}/.gradle"
fi

if [[ ! -d "${GRADLE_DIR}" ]]; then
  if ! mkdir -p "${GRADLE_DIR}"; then
    echo >&2 "Unable to create directory ${GRADLE_DIR} (does not exist)"
    exit 1
  fi
fi

GRADLE_PROPERTIES_FILE="${GRADLE_DIR}/gradle.properties"
if [[ -f "${GRADLE_PROPERTIES_FILE}" ]]; then
  if ! TMP_FILE="$(mktemp)"; then
    echo >&2 "Unable to create temporary file"
    exit 1
  fi

  cat "${GRADLE_PROPERTIES_FILE}" | grep -v "^openLimitsJavaClientJarPath=" > "${TMP_FILE}"

  if ! echo "openLimitsJavaClientJarPath=${JAR_PATH}" >> "${TMP_FILE}"; then
    echo >&2 "Unable to add new token to ${TMP_FILE}"
    exit 1
  fi

  if ! mv "${TMP_FILE}" "${GRADLE_PROPERTIES_FILE}"; then
    echo >&2 "Unable to move ${TMP_FILE} to ${GRADLE_PROPERTIES_FILE}"
    exit 1
  fi
else
  echo "openLimitsJavaClientJarPath=${JAR_PATH}" > "${GRADLE_PROPERTIES_FILE}"
fi

echo "${GRADLE_PROPERTIES_FILE} updated - openLimitsJavaClientJarPath=${JAR_PATH}."
echo "You may need to stop any running gradle daemons to ensure the changes take effect."
echo "eg: \`./gradlew --stop\`"
