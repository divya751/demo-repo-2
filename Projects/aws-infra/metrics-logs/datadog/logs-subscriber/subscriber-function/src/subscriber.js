const AWS = require('aws-sdk');

function describeSubscriptionFilters(cloudWatchLogs, datadogFunctionArn) {
  let logGroups = cloudWatchLogs.describeLogGroups({}).promise();
  return logGroups.then(data => {
    return Promise.all(data.logGroups.map(logGroup => {
      return cloudWatchLogs.describeSubscriptionFilters({logGroupName: logGroup.logGroupName}).promise().then(response => {
        let hasDatadogFunctionSubscription = response.subscriptionFilters.filter(each => {
          return datadogFunctionArn === each.destinationArn;
        }).length > 0;

        let logGroupStatus = {
          logGroupName: logGroup.logGroupName,
          hasDatadogFunctionSubscription: hasDatadogFunctionSubscription
        };
        return Promise.resolve(logGroupStatus);
      });
    }));
  });
}

function getFilterPattern(logGroupName) {
  if (logGroupName.includes('/aws/lambda')) {
    return 'level';
  } else {
    return '';
  }
}

function filterLogGroupsMissingSubscription(subscriptionFilters) {
  return new Promise(resolve => {
    resolve(subscriptionFilters.filter(each => !each.hasDatadogFunctionSubscription));
  });
}

function putSubscriptionFilter(logGroupsMissingSubscription, datadogFunctionArn, cloudWatchLogs, logger) {
  return Promise.all(logGroupsMissingSubscription.map(logGroup => {
    let putSubscriptionFilterParams = {
      destinationArn: datadogFunctionArn,
      filterName: logGroup.logGroupName + '-DatadogLogsSubscriptionFilter',
      filterPattern: getFilterPattern(logGroup.logGroupName),
      logGroupName: logGroup.logGroupName,
      distribution: 'ByLogStream'
    };
    logger.info('About to create log group subscription for: %s, %s', JSON.stringify(logGroup), JSON.stringify(putSubscriptionFilterParams));
    return cloudWatchLogs.putSubscriptionFilter(putSubscriptionFilterParams).promise().then(
        () => {
          logger.info('Log group subscription filter created: %s', JSON.stringify(putSubscriptionFilterParams));
          return Promise.resolve(putSubscriptionFilterParams);
        }, error => {
          logger.error('Unable to putSubscriptionFilter: %s', JSON.stringify(error));
          return Promise.reject(error);
        });
  }));
}

exports.runForAllLogGroups = (params, logger) => {
  logger.info('About to check and update subscription filters with params %s.', JSON.stringify(params));
  let cloudWatchLogs = new AWS.CloudWatchLogs({region: params.region}),
      datadogFunctionArn = params.datdogFunctionArn;
  return describeSubscriptionFilters(cloudWatchLogs, datadogFunctionArn)
      .then(subscriptionFilters => filterLogGroupsMissingSubscription(subscriptionFilters))
      .then(logGroupsMissingSubscription => putSubscriptionFilter(logGroupsMissingSubscription, datadogFunctionArn, cloudWatchLogs, logger));
};