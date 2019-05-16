const AWS = require('aws-sdk');
const logger = require('./log')('rollback-stack');

const cancelUpdateStack = (cloudformation, stackResource) => {
  const params = {
    StackName: stackResource.StackName,
  };

  return cloudformation.cancelUpdateStack(params).promise()
    .then(() => logger.info(`${stackResource.StackName} is rolling back`))
    .catch(() => logger.error(`Failed to cancel stack update ${stackResource.StackName}`));
};

const stackStatusIsUpdateInProgress = (cloudformation, stackResource) => {
  return cloudformation.describeStacks({StackName: stackResource.StackName}).promise()
    .then(data => data.Stacks[0].StackStatus === "UPDATE_IN_PROGRESS")
    .catch(() => false);
};

const findStacksAndCancelUpdate = (cloudformation, event) => {
  logger.info('Received an event: %s', JSON.stringify(event));
  const params = {
    LogicalResourceId: "TaskDefinition",
    PhysicalResourceId: event.detail.taskDefinitionArn,
  };
  return cloudformation.describeStackResources(params).promise()
    .then(data => {
      return Promise.all(data.StackResources.map(stack => {
        return stackStatusIsUpdateInProgress(cloudformation, stack)
          .then(inProgress => inProgress && cancelUpdateStack(cloudformation, stack))
      }))
    })
};

exports.findStacksAndCancelUpdate = findStacksAndCancelUpdate;

exports.handler = (event, context, callback) => {
  findStacksAndCancelUpdate(new AWS.CloudFormation(), event)
    .then(() => callback())
    .catch(err => {
      logger.error(`Cancel stack update failed: ${err}`);
      callback(err);
    });
};
