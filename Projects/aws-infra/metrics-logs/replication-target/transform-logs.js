const zlib = require('zlib');

exports.handler = (event, context, callback) => {
  const records = [];

  for (let i = 0; i < event.records.length; i++) {
    const record = event.records[i];
    const buffer = Buffer.from(record.data, 'base64');

    zlib.unzip(buffer, (err, buffer) => {
      if (err) {
        records.push({
          recordId: record.recordId,
          result: 'ProcessingFailed',
          data: record.data
        });
      } else {
        records.push({
          recordId: record.recordId,
          result: 'Ok',
          data: buffer.toString('base64')
        });
      }

      if (event.records.length === records.length) {
        console.log("RESULT:", JSON.stringify({records}, null, 2));
        callback(null, {records});
      }
    });
  }
};
