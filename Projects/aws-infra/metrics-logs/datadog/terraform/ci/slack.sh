#!/bin/sh
set -e
app_key=${DATADOG_APP_KEY}
api_key=${DATADOG_API_KEY}
channel_name=${ACCOUNT_ALIAS}

slack_api_url="https://app.datadoghq.com/api/v1/integration/slack?api_key=${api_key}&application_key=${app_key}&run_check=true"

slack_config='{
        "service_hooks": [
          {
            "account": "Main_Account",
            "url": "https://hooks.slack.com/services/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"
          }
        ],
        "channels": [
          {
            "channel_name": "#'${channel_name}'",
            "transfer_all_user_comments": "false",
            "account": "Main_Account"
          }
        ]
      }'

slack_integration_response=`curl -sw "%{http_code}" -o /dev/null -X GET ${slack_api_url}`

if [ ${slack_integration_response} -eq "404" ]; then
  echo "No Slack integration found. Creating..."
  curl -X POST -H "Content-type: application/json" -d "${slack_config}" ${slack_api_url}
else
  echo "Slack integration was found. Updating..."
  curl -X PUT -H "Content-type: application/json" -d "${slack_config}" ${slack_api_url}
fi
