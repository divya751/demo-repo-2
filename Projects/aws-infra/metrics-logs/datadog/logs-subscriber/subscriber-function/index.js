const logger = require('./src/log')('logs-subscriber');
const subscriber = require('./src/subscriber');

exports.handler = (event, context, callback) => {
  logger.info('Received an event: %s, context: %s', JSON.stringify(event), JSON.stringify(context));
  if (event.source === 'aws.events' && event['detail-type'] === 'Scheduled Event') {
    let runForAllParams = {
      region: event.region,
      datdogFunctionArn: process.env.DATADOG_FUNCTION_ARN
    };
    return subscriber.runForAllLogGroups(runForAllParams, logger).then(result => {
      return Promise.resolve(result);
    }, (error) => {
      logger.error(error);
      return Promise.reject(error);
    });
  }

  callback(null, 'ok');
};