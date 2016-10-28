#!/usr/bin/env bash

# ----------
# API Endpoint
# ----------
# Default WEBHOOK to post messages
if [[ -n ${WEBHOOK} ]]; then
  echo "INFO: The Slack API WEBHOOK was passed via the command line (-w)"
elif [[ -n ${SLACK_WEBHOOK} ]]; then
  echo "INFO: The Slack API TOKEN was set as a system variable"
  WEBHOOK=${SLACK_WEBHOOK}
else
  echo "INFO: Using default Slack API endpoint to POST messages..."
  WEBHOOK=${WEBHOOK-'https://hooks.slack.com/services/'}
fi

# ----------
# Environment
# ----------
HOSTNAME=${hostname-$(hostname -s)}
CONFIG="/etc/slack.d"
IPCONFIG="/tmp/ip.txt"

# ----------
# IP
# ---------
# Check for the IP address every 2 hours. Use cache for anything < 2 hours
if [[ ! -f "${IPCONFIG}" ]]; then
  echo "INFO: ${IPCONFIG} does not exist. Creating..."
  IP=$(curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
  touch ${IPCONFIG}
  echo "IP=${IP}" > ${IPCONFIG}
else
  if test "find '${IPCONFIG}' -mmin +120"; then
    echo "INFO: ${IPCONFIG} is less than 2 hours old. We will use the cached IP in ${IPCONFIG}..."
  else
    IP=$(curl -s checkip.dyndns.org|sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
    echo "WARNING: ${IPCONFIG} is more than 2 hours old. Updating the IP in ${IPCONFIG}..."
    echo "IP=${IP}" > ${IPCONFIG}
  fi
fi

source ${IPCONFIG}

# ----------
# Commands
# ----------
function GET_HELP() {
    echo "Usage: [options]"
    echo "  options:"
    echo "-a, Attachment                Sends a messages as an attachment."
    echo "-A, Author                    Small text used to display the author's name."
    echo "-b, Author Link               A URL that will hyperlink the author_name text mentioned above. (Author name is required)."
    echo "-B, Author Icon               A URL that displays a small image to the left of the author_name text.(Author name is required)."
    echo "-c, Channel                   The location the messages should be delivered."
    echo "-C, Color                     This value is used to color the border along the left side of the message attachment."
    echo "-e, Environment               This value is used to provide the message with an environment identifier."
    echo "-h, Help                      Show the command options for Slack."
    echo "-i, Icon                      A URL to an image file that will be displayed inside a message attachment."
    echo "-I, Image                     Small text used to display the author's name."
    echo "-m, Mode                      Mode toggles application specific behaviors (e.g., preconfigured Monit settings)."
    echo "-N, Thumbnail                 A URL to an image file that will be displayed as a thumbnail on the right side of a message attachment."
    echo "-p, Pretext                   This is optional text that appears above the message attachment block."
    echo "-s, Status                    An optional value that can either be one of ok, info, warn or error."
    echo "-Z, Text                      This is the main text in a message attachment, and can contain standard message markup."
    echo "-T, Title                     The title is displayed as larger, bold text near the top of a message attachmen."
    echo "-L, Title Link                A valid URL in the will ensure the title text will be hyperlinked."
    echo "-k, Token                     Authenticates the POST to Slack."
    echo "-u, Username                  User that posts the message."
    echo "-w, Webhook                   The Slack API service endpoint to POST messages."
    exit 1
}

# Check if any arguments were passed
if [[ $# -eq 0 ]]; then
    GET_HELP
    exit 1
else
  while getopts ":a:A:b:B:c:C:e:h:i:I:m:N:p:s:Z:T:L:k:u:w" opt; do
    case ${opt} in
      a) ATTACHMENT="true" ;;
      A) AUTHOR="${OPTARG}" ;;
      b) AUTHORICON="${OPTARG}" ;;
      B) AUTHORLINK="${OPTARG}" ;;
      c) CHANNEL="${OPTARG}" ;;
      C) COLOR="${OPTARG}" ;;
      e) ENV="${OPTARG}" ;;
      h) GET_HELP ;;
      i) ICON="${OPTARG}" ;;
      I) IMAGE="${OPTARG}" ;;
      m) MODE="${OPTARG}" ;;
      N) THUMBNAIL="${OPTARG}" ;;
      p) PRETEXT="${OPTARG}" ;;
      s)
          if test "${OPTARG}" = "ok"; then PRIORITY="OK"; fi
          if test "${OPTARG}" = "info"; then PRIORITY='INFO'; fi
          if test "${OPTARG}" = "warn"; then PRIORITY='WARN'; fi
          if test "${OPTARG}" = "error"; then PRIORITY='ERROR'; fi
          ;;
      Z) TEXT="${OPTARG}" ;;
      T) TITLE="${OPTARG}" ;;
      L) TITLELINK="${OPTARG}" ;;
      k) TOKEN="${OPTARG}" ;;
      u) USERNAME="${OPTARG}" ;;
      w) WEBHOOK="${OPTARG}" ;;
      esac
      done
fi

# ----------
# Check for Token
# ----------
echo "${SLACK_TOKEN}"
# Default TOKEN to post messages
if [[ -n ${TOKEN} ]]; then
  echo "INFO: The Slack API TOKEN was passed via the command line (-k)"
elif [[ -n ${SLACK_TOKEN} ]]; then
  echo "INFO: The Slack API TOKEN was set as a system variable"
  TOKEN=${SLACK_TOKEN}
else
  echo "ERROR: No Slack API TOKEN was found. Can not proceed with posting messages to the API without one."
  exit 1
fi

# ----------
# Service Specific Configurations
# ----------
# Service specific configurations are passed using -m <config>
# For example, the include monit config (/etc/slack.d/monit) will leverage mMonit specific environment variables to set message attributes.

# We look for this first, if no config exists we use defaults

if [[ -n "${MODE}" ]]; then
  test -d "${CONFIG}" && echo "INFO: The ${CONFIG} direcotry exists" || echo "WARNING: The ${CONFIG} direcotry does not exist. Creating..."; mkdir -p ${CONFIG}
  curl -o "${CONFIG}/${MODE}" -z "${CONFIG}/${MODE}" "https://raw.githubusercontent.com/gonace/ob_hacky_slack/develop/etc/slack.d/${MODE}" --verbose
  if [[ -z "${MODE}" ]]; then
    echo "INFO: No Monit variables are present"
  else
    source "${CONFIG}/${MODE}"
  fi
else

  # ----------
  # Style Setting
  # ----------
  # Certain elements should be part of a message. Rather than simply exit, we post placeholders to highlight the fact the information is missing
  # Set stauts attributes
  if test "${PRIORITY}" = "OK"; then echo "INFO: STATUS (-s) was set to OK..."; ICON=${ICON:-'good'} && COLOR=${COLOR:-'#36a64f'}; fi
  if test "${PRIORITY}" = "INFO"; then echo "INFO: STATUS (-s) was set to INFO..."; ICON=${ICON:-'info'} && COLOR=${COLOR:-'#439FE0'}; fi
  if test "${PRIORITY}" = "WARN"; then echo "INFO: STATUS (-s) was set to WARN..."; ICON=${ICON:-'warn'} && COLOR=${COLOR:-'#ed7d21'}; fi
  if test "${PRIORITY}" = "ERROR"; then echo "INFO: STATUS (-s) was set to ERROR..."; ICON=${ICON:-'error'} && COLOR=${COLOR:-'#E21B6C'}; fi
  if test -z "${USERNAME}"; then echo "INFO: A USERNAME (-u) was not specified for this POST to the Slack API. Setting a default username..."; USERNAME="${IP}"; fi
fi

# ----------
# Test Message
# ----------
# We will test for key parts of the message as they should be present
if [[ -z "${TEXT+x}" ]]; then echo "WARNING: You do not have any TEXT (-t) specified in the message."; TEXT="${TEXT:-'This message is missing TEXT'}"; else echo "INFO: TEXT is set to '${TEXT}'"; fi
if [[ -z "${TITLE+x}" ]]; then echo "WARNING: You do not have a TITLE (-T) specified for the message."; TITLE=${TITLE:-'This message is missing a TITLE'}; else echo "INFO: TITLE is set to '${TITLE}'"; fi
if [[ -z "${PRETEXT+x}" ]]; then echo "WARNING: You do not have a PRETEXT (-p) specified for the message."; PRETEXT=${PRETEXT:-'This message is missing a PRETEXT'}; else echo "INFO: PRETEXT is set to '${PRETEXT}'"; fi
if [[ -z "${CHANNEL+x}" ]]; then echo "WARNING: A CHANNEL (-c) was not set. Using the default CHANNEL..."; CHANNEL=${CHANNEL:-'general'}; else echo "INFO: CHANNEL is set to '${CHANNEL}'"; fi
if [[ -z "${PRIORITY+x}" ]]; then echo echo "INFO: STATUS (-s) was not set. Setting a default STATUS to INFO..."; PRIORITY=${PRIORITY:-'INFO'} && ICON=${ICON:-'info'} && COLOR=${COLOR:-'#439FE0'}; else echo "INFO: PRIORITY is set to '${PRIORITY}'"; fi
if [[ -z "${ENV+x}" ]]; then echo "INFO: A ENV (-e) was not set. Using the default ENV..."; ENV=${ENV:-'Development'}; else echo "INFO: ENV is set to '${ENV}'"; fi

# ----------
# Send Message
# ----------
function SEND() {
  # The complete Slack API payload, including attachments#
  if [[ ${ATTACHMENT} = "true" ]]; then
    PAYLOAD="payload={ \
      \"channel\": \"${CHANNEL}\", \
      \"username\": \"${USERNAME}\", \
      \"pretext\": \"${PRETEXT}\", \
      \"color\": \"${COLOR}\", \
      \"icon_emoji\": \":${ICON}:\", \
      \"text\": \"${TEXT}\", \
      \"mrkdwn\": \"true\", \
      \"attachments\": [{
      \"fallback\": \"${FALLBACK}\", \
      \"color\": \"${COLOR}\", \
      \"pretext\": \"${PRETEXT}\", \
      \"author_name\": \"${AUTHOR}\", \
      \"author_link\": \"${AUTHORLINK}\", \
      \"author_icon\": \"${AUTHORICON}\", \
      \"title\": \"${TITLE}\", \
      \"title_link\": \"${TITLELINK}\", \
      \"text\": \"${TEXT}\", \
      \"mrkdwn_in\": [\"text\",\"pretext\",\"fields\"], \
      \"fields\": [{\"title\": \"Status\",\"value\": \"${PRIORITY}\",\"short\": \"true\"}, {\"title\": \"Host\",\"value\": \"${IP}\",\"short\": \"true\"}, {\"title\": \"Environment\",\"value\": \"${ENV}\",\"short\": \"true\"} ], \
      \"image_url\": \"${IMAGE}\", \
      \"thumb_url\": \"${THUMBNAIL}\" \
    }]}"
   else
    PAYLOAD="payload={ \
      \"channel\": \"${CHANNEL}\", \
      \"username\": \"${USERNAME}\", \
      \"pretext\": \"${PRETEXT}\", \
      \"color\": \"${COLOR}\", \
      \"icon_emoji\": \":${ICON}:\", \
      \"text\": \"${TEXT}\", \
      \"mrkdwn\": \"true\" \
    }"
  fi

  # Send the payload to the Slack API
  echo "OK: All tests passed, sending message to Slack API..."
  POST=$(curl -s -S -X POST --data-urlencode "${PAYLOAD}" "${WEBHOOK}${TOKEN}");

  # Check if the message posted to the Slack API. A successful POST should return "ok". Anything other than "ok" indicates an issue
  if test "${POST}" != ok; then echo "ERROR: The POST to the Slack API failed (${POST})" && return 1; else echo "OK: Message successfully sent to the channel ${CHANNEL} via the Slack API"; fi
}

SEND
exit 1
