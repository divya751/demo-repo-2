const AWS = require('aws-sdk');
const logger = require('./log')('stack-termination');
const deleteTag = 'DeleteAfter';

function getCfnRoleARN(cloudformation, logger) {
  return new Promise((resolve, reject) => {
    cloudformation.listExports({}, (err, data) => {
      if (err) {
        logger.error('Failed to get Cloudformation Role ARN: %s', JSON.stringify(err));
        reject(err);
      } else {
        const exportVal = data.Exports.find(e => e.Name === 'CloudformationRoleARN');

        if (exportVal) {
          resolve(exportVal.Value);
        } else {
          reject(new Error('No CloudformationRoleARN export found'));
        }
      }
    });
  });
}

function getStacks(cloudformation, logger) {
  return new Promise((resolve, reject) => {
    cloudformation.describeStacks({}, (err, data) => {
      if (err) {
        logger.error('Failed to get stacks %s', JSON.stringify(err));
        reject(err);
      } else {
        resolve(data.Stacks);
      }
    });
  });
}

function deleteStack(cloudformation, logger, stack, cfnRoleARN) {
  logger.info('Delete Stack %s', JSON.stringify(stack, null, 2));

  return new Promise((resolve, reject) => {
    cloudformation.deleteStack({
      StackName: stack.StackId,
      RoleARN: cfnRoleARN
    }, (err, data) => {
      if (err) {
        logger.error('Failed to delete stack: %s. Error: %s', stack.StackId, JSON.stringify(err));
        reject(err);
      } else {
        resolve(data);
      }
    });
  });
}

function findAndDeleteStacks(cloudformation, logger) {
  return Promise.all([
    getCfnRoleARN(cloudformation, logger),
    getStacks(cloudformation, logger)
  ]).then(([cfnRoleARN, stacks]) => {
    logger.info('Checking %d stacks', stacks.length);

    return Promise.all(stacks.map(stack => {
      const tag = stack.Tags.find(tag => tag.Key === deleteTag);
      if (tag && Date.now() > Date.parse(tag.Value)) {
        return deleteStack(cloudformation, logger, stack, cfnRoleARN);
      }
    }))
  });
}

exports.findAndDeleteStacks = findAndDeleteStacks;

exports.handler = (event, context, callback) => {
  findAndDeleteStacks(new AWS.CloudFormation(), logger)
    .then(() => callback())
    .catch(err => {
      logger.error('Error %s', JSON.stringify(err));
      callback(err);
    });
};
