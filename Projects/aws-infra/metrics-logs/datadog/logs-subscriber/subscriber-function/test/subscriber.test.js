const index = require('../index');
const assert = require('chai').assert;
const sinon = require('sinon');
const fs = require('fs');
const AWS = require('aws-sdk-mock');

process.env.DATADOG_FUNCTION_ARN = 'arn:aws:lambda:eu-west-1:925832396712:function:DatadogLogs';

describe('subscriber', () => {
  describe('scheduled event', () => {
    let putSubscriptionFilterSpy,
        describeLogGroupsSpy;

    beforeEach(() => {
      putSubscriptionFilterSpy = sinon.spy();
      describeLogGroupsSpy = sinon.spy();

      AWS.mock('CloudWatchLogs', 'putSubscriptionFilter', (params, callback) => {
        let putSubscriptionFilterResponse = JSON.parse(fs.readFileSync('test/put-subscription-filter-response.json'));
        callback(null, putSubscriptionFilterResponse);
        putSubscriptionFilterSpy();
      });

      AWS.mock('CloudWatchLogs', 'describeLogGroups', (params, callback) => {
        let describeLogGroupsResponse = JSON.parse(fs.readFileSync('test/describe-log-groups-response.json'));
        callback(null, describeLogGroupsResponse);
        describeLogGroupsSpy();
      });
    });

    afterEach(() => {
      AWS.restore('CloudWatchLogs');
    });

    it('should check and put subscription filters', async () => {
      let cloudWatchEvent = JSON.parse(fs.readFileSync('test/scheduled-event.json'));

      AWS.mock('CloudWatchLogs', 'describeSubscriptionFilters', (params, callback) => {
        let describeSubscriptionFiltersResponse = JSON.parse(fs.readFileSync('test/describe-subscription-filters-empty-response.json'));
        callback(null, describeSubscriptionFiltersResponse);
      });

      let result = await index.handler(cloudWatchEvent, {});

      assert.isNotEmpty(result);
    });

    it('should check and skip creating subscription filters if they already exist', async () => {
      let cloudWatchEvent = JSON.parse(fs.readFileSync('test/scheduled-event.json'));

      AWS.mock('CloudWatchLogs', 'describeSubscriptionFilters', (params, callback) => {
        let describeSubscriptionFiltersResponse = JSON.parse(fs.readFileSync('test/describe-subscription-filters-datadogLogs-response.json'));
        callback(null, describeSubscriptionFiltersResponse);
      });

      let result = await index.handler(cloudWatchEvent, {});

      assert.isEmpty(result);
      assert.isTrue(describeLogGroupsSpy.called);
      assert.isFalse(putSubscriptionFilterSpy.called);
    });
  });
});
