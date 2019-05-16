const AWS = require('aws-sdk');
const s3 = new AWS.S3({apiVersion: '2006-03-01'});

exports.handler = (event, context, callback) => {
  const Bucket = event.Records[0].s3.bucket.name;
  const Key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));

  s3.getObjectAcl({Bucket, Key}, (err, data) => {
    if (err) {
      console.log(`ERROR - can not get ACL for ${Bucket}/${Key}`);
      return callback(err);
    }

    data.Grants.push({
      Grantee: {
        DisplayName: 'husdyrfag.aws',
        ID: process.env.HusdyrfagCanonicalId,
        Type: 'CanonicalUser'
      },
      Permission: 'READ'
    });

    s3.putObjectAcl({Bucket, Key, AccessControlPolicy: data}, (err, data) => {
      if (err) {
        console.log(`ERROR - can not update ACL for ${Bucket}/${Key}`);
        return callback(err);
      }
      callback(null, `SUCCESS - ${Bucket}/${Key}`);
    });
  });
};
