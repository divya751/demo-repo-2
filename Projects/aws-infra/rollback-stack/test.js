/*global describe, beforeEach, it */
const {findStacksAndCancelUpdate} = require('./index');
const {assert} = require('chai');
const sinon = require('sinon');
sinon.assert.expose(assert, {prefix: ''});

describe('Rollback stack lambda', () => {
  let cloudformation;

  beforeEach(() => {
    cloudformation = {
      describeStackResources: sinon.stub(),
      describeStacks: sinon.stub().returns({promise: sinon.stub().resolves()}),
      cancelUpdateStack: sinon.stub().returns({promise: sinon.stub().resolves()})
    };

    kallback = {
      callback: sinon.stub()
    };
  });

  const event = {
    detail: {
      taskDefinitionArn: "arn:aws:ecs:eu-west-1:123456789012:task-definition/MyTask:22"
    }
  };

  it('does nothing if stack resource is not found', () => {
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: []})});
    findStacksAndCancelUpdate(cloudformation, event);
    assert.calledOnce(cloudformation.describeStackResources);
    assert.notCalled(cloudformation.cancelUpdateStack);
  });

  it('should lookup stack if stacks are found', () => {
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: [{StackName: "myStack"}]})});

    return findStacksAndCancelUpdate(cloudformation, event)
      .then(() => {
        assert.calledOnce(cloudformation.describeStackResources);
        assert.calledOnce(cloudformation.describeStacks);
        assert.calledWith(cloudformation.describeStacks, {StackName: "myStack"})
      });
  });

  it('should not cancel stack if stack status is not UPDATE_IN_PROGRESS', () => {
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: [{StackName: "myStack"}]})});
    cloudformation.describeStacks.returns({promise: sinon.stub().resolves({Stacks: [{StackStatus: "UPDATE_COMPLETE"}]})});

    return findStacksAndCancelUpdate(cloudformation, event)
      .then(() => {
        assert.calledOnce(cloudformation.describeStackResources);
        assert.calledOnce(cloudformation.describeStacks);
        assert.notCalled(cloudformation.cancelUpdateStack);
      });
  });

  it('should cancel stack if stack status is UPDATE_IN_PROGRESS', () => {
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: [{StackName: "myStack"}]})});
    cloudformation.describeStacks.returns({promise: sinon.stub().resolves({Stacks: [{StackStatus: "UPDATE_IN_PROGRESS"}]})});

    return findStacksAndCancelUpdate(cloudformation, event)
      .then(() => {
        assert.calledOnce(cloudformation.describeStackResources);
        assert.calledOnce(cloudformation.describeStacks);
        assert.calledOnce(cloudformation.cancelUpdateStack);
      });
  });

  it('should not cancel stack if fails to get stack status', () => {
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: [{StackName: "myStack"}]})});
    cloudformation.describeStacks.returns({promise: sinon.stub().rejects(new Error('LOL'))});

    return findStacksAndCancelUpdate(cloudformation, event)
      .then(() => {
        assert.calledOnce(cloudformation.describeStackResources);
        assert.calledOnce(cloudformation.describeStacks);
        assert.notCalled(cloudformation.cancelUpdateStack);
      });
  });

  it('should cancel all pending stacks', () => {
    const stacks = [{StackName: "myStack"}, {StackName: "myOtherStack"}];
    cloudformation.describeStackResources.returns({promise: sinon.stub().resolves({StackResources: stacks})});
    cloudformation.describeStacks.onCall(0).returns({promise: sinon.stub().resolves({Stacks: [{StackStatus: "UPDATE_IN_PROGRESS"}]})});
    cloudformation.describeStacks.onCall(1).returns({promise: sinon.stub().resolves({Stacks: [{StackStatus: "UPDATE_COMPLETE"}]})});

    return findStacksAndCancelUpdate(cloudformation, event)
      .then(() => {
        assert.calledOnce(cloudformation.describeStackResources);
        assert.calledTwice(cloudformation.describeStacks);
        assert.calledOnce(cloudformation.cancelUpdateStack);
      });
  });
});

