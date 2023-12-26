#!/bin/bash

set +e

function arg() {
  local _format="${1}"
  local _val="${2}"

  if [[ "${#_val}" == 0 || "${_val}" == "false" ]]; then
    return
  fi

  printf " ${_format}" "${_val}"
}

function default() {
  local _default="${1}"
  local _result="${2}"
  local _val="${3}"
  local _defaultifnotset="${4}"

  if [[ "${_defaultifnotset}" == "true" ]]; then
    if [ "${#_val}" = 0 ]; then
      echo "${_default}"
      return
    fi
  fi

  if [[ "${_val}" != "${_default}" ]]; then
    echo "${_result}"
  else
    echo "${_val}"
  fi
}

INPUT_SOURCE=$(default "${GITHUB_WORKSPACE}" "${GITHUB_WORKSPACE}/${INPUT_SOURCE}" "${INPUT_SOURCE}" 'true')
INPUT_CONFIG=$(default "/.gitleaks/UDMSecretChecks.toml" "${GITHUB_WORKSPACE}/${INPUT_CONFIG}" "${INPUT_CONFIG}" 'true')
INPUT_REPORT_FORMAT=$(default 'json' "${INPUT_REPORT_FORMAT}" "${INPUT_REPORT_FORMAT}" 'true')
INPUT_REDACT=$(default 'true' 'false' "${INPUT_REDACT}" 'true')
INPUT_FAIL=$(default 'true' 'false' "${INPUT_FAIL}" 'true')
INPUT_VERBOSE=$(default 'true' 'false' "${INPUT_VERBOSE}" 'true')
INPUT_LOG_LEVEL=$(default 'info' "${INPUT_LOG_LEVEL}" "${INPUT_LOG_LEVEL}" 'true')

echo "----------------------------------"
echo "INPUT PARAMETERS"
echo "----------------------------------"
echo "INPUT_SOURCE: ${INPUT_SOURCE}"
echo "INPUT_CONFIG: ${INPUT_CONFIG}"
echo "INPUT_BASELINE_PATH: ${INPUT_BASELINE_PATH}"
echo "INPUT_REPORT_FORMAT: ${INPUT_REPORT_FORMAT}"
echo "INPUT_NO_GIT: ${INPUT_NO_GIT}"
echo "INPUT_REDACT: ${INPUT_REDACT}"
echo "INPUT_FAIL: ${INPUT_FAIL}"
echo "INPUT_VERBOSE: ${INPUT_VERBOSE}"
echo "INPUT_LOG_LEVEL: ${INPUT_LOG_LEVEL}"
echo "----------------------------------"

echo "Setting Git safe directory (CVE-2022-24765)"
echo "git config --global --add safe.directory ${GITHUB_WORKSPACE}"
git config --global --add safe.directory "${GITHUB_WORKSPACE}"
echo "----------------------------------"

command="gitleaks detect --no-git --verbose --no-color"
if [ -f "${INPUT_CONFIG}" ]; then
  command+=$(arg '--config %s' "${INPUT_CONFIG}")
fi

command+=$(arg '--report-format %s' "${INPUT_REPORT_FORMAT}")
command+=$(arg '--log-level %s' "${INPUT_LOG_LEVEL}")
command+=$(arg '--report-path %s' "${GITHUB_WORKSPACE}/gitleaks-report.${INPUT_REPORT_FORMAT}")
command+=$(arg '--source %s' "${INPUT_SOURCE}")

echo "Running GitLeaks $(gitleaks version)"
echo "----------------------------------"
echo "${command}"
OUTPUT=$(eval "${command}")
exitcode=$?
echo "Exitcode $exitcode"

if [ ${exitcode} -eq 0 ]; then
  GITLEAKS_RESULT="✅ PASSED! No leaks found"
elif [ ${exitcode} -eq 1 ]; then
  GITLEAKS_RESULT="❌ FAILED! GitLeaks found a leak"
else
  GITLEAKS_RESULT="GitLeaks unknown error"
fi

echo "----------------------------------"
echo -e "${OUTPUT}"
EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)
echo "output<<$EOF" >> $GITHUB_OUTPUT
echo -e "${OUTPUT}" >> $GITHUB_OUTPUT
echo "$EOF" >> $GITHUB_OUTPUT

echo "report=gitleaks-report.${INPUT_REPORT_FORMAT}" >> $GITHUB_OUTPUT
echo "result=${GITLEAKS_RESULT}" >> $GITHUB_OUTPUT
echo "command=${command}" >> $GITHUB_OUTPUT
echo "exitcode=${exitcode}" >> $GITHUB_OUTPUT

echo -e "GitLeaks Summary: ${GITLEAKS_RESULT}\n" >> $GITHUB_STEP_SUMMARY
echo -e "${OUTPUT}" >>"$GITHUB_STEP_SUMMARY"

if [ ${exitcode} -eq 1 ]; then
  echo "::error::${GITLEAKS_RESULT}"
fi
exit ${exitcode}