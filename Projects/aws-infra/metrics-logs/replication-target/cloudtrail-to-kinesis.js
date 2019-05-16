'use strict';
const AWS = require('aws-sdk');
const zlib = require('zlib');
const kinesis = new AWS.Kinesis();
const s3 = new AWS.S3({ apiVersion: '2006-03-01' });

exports.handler = (event, context, callback) => {
  const Bucket = event.Records[0].s3.bucket.name;
  const Key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

  s3.getObject({Bucket, Key}, (err, data) => {
    if (err) {
      return callback(`Error getting object ${Key} from bucket ${Bucket}. Make sure they exist and your bucket is in the same region as this function.`);
    }

    zlib.gunzip(data.Body, function(error, buff) {
      if (error) {
        return callback(`Error unzipping object ${Key} from bucket ${Bucket}\n${error.message}`);
      }

      const results = JSON.parse(buff.toString('ascii'));

      results.Records.forEach(record => {
        const Data = JSON.stringify(record);
        kinesis.putRecord({Data, PartitionKey: 'cloudtrail', StreamName: 'ksLogs'}, err => {
          callback(err ? `Error putRecord with data: ${Data} to kinesis.` : null);
        });
      });
    });
  });
};
