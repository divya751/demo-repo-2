/*global describe, beforeEach, it */
const {findAndDeleteStacks} = require('./index');
const {assert} = require('chai');
const sinon = require('sinon');
const log = require('./log')('stack-termination');
sinon.assert.expose(assert, {prefix: ''});

describe('Stack termination lambda', () => {
  let cloudformation, logger;

  beforeEach(() => {
    cloudformation = {
      listExports: sinon.stub(),
      describeStacks: sinon.stub(),
      deleteStack: sinon.stub()
    };
    logger = log;
  });

  it('fetches role ARN and stacks', () => {
    findAndDeleteStacks(cloudformation);

    assert.calledOnce(cloudformation.listExports);
    assert.calledOnce(cloudformation.describeStacks);
  });

  it('fails if it fails to get the role ARN', () => {
    cloudformation.listExports.yields(new Error('No can do'));

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        throw new Error('Should fail')
      })
      .catch(err => {
        assert.equal(err.message, 'No can do');
      });
  });

  it('fails if the cloudformation role stack export is not found', () => {
    cloudformation.listExports.yields(null, {Exports: [{}]});

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        throw new Error('Should fail')
      })
      .catch(err => {
        assert.equal(err.message, 'No CloudformationRoleARN export found');
      });
  });

  it('fails if it cannot describe stacks', () => {
    cloudformation.describeStacks.yields(new Error('No can do'));

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        throw new Error('Should fail')
      })
      .catch(err => {
        assert.equal(err.message, 'No can do');
      });
  });

  it('Silently succeeds if there are no stacks', () => {
    cloudformation.listExports.yields(null, {Exports: [{Name: 'CloudformationRoleARN', Value: 'aws:iam'}]});
    cloudformation.describeStacks.yields(null, {Stacks: []});

    return findAndDeleteStacks(cloudformation, logger);
  });

  it('Silently succeeds if there are no stacks to delete', () => {
    cloudformation.listExports.yields(null, {Exports: [{Name: 'CloudformationRoleARN', Value: 'aws:iam'}]});
    cloudformation.describeStacks.yields(null, {
      Stacks: [{Tags: []}, {Tags: [{Key: 'Blabla', Value: 'Nope'}]}]
    });

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        assert.equal(cloudformation.deleteStack.callCount, 0);
      });
  });

  it('Deletes stack whose time is up', () => {
    const deleteAfter = new Date(new Date().getTime() - (60 * 60 * 1000));

    cloudformation.listExports.yields(null, {Exports: [{Name: 'CloudformationRoleARN', Value: 'aws:iam'}]});
    cloudformation.describeStacks.yields(null, {
      Stacks: [
        {StackId: 'Stack1', Tags: []},
        {StackId: 'Stack2', Tags: [{Key: 'DeleteAfter', Value: deleteAfter.toISOString()}]}]
    });

    cloudformation.deleteStack.yields(null, {});

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        assert.calledOnce(cloudformation.deleteStack);
        assert.deepEqual(cloudformation.deleteStack.getCall(0).args[0], {
          StackName: 'Stack2',
          RoleARN: 'aws:iam'
        });
      });
  });

  it('Does not delete stacks not yet up for deletion', () => {
    const deleteAfter = new Date(new Date().getTime() + (24 * 60 * 60 * 1000));

    cloudformation.listExports.yields(null, {Exports: [{Name: 'CloudformationRoleARN', Value: 'aws:iam'}]});
    cloudformation.describeStacks.yields(null, {
      Stacks: [{Tags: [{Key: 'DeleteAfter', Value: deleteAfter.toISOString()}]}]
    });

    return findAndDeleteStacks(cloudformation, logger)
      .then(() => {
        assert.equal(cloudformation.deleteStack.callCount, 0);
      });
  });
});

