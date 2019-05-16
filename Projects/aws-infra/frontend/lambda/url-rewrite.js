'use strict';

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;

  if (/^\/.+\//.test(request.uri) && !/\..+$/.test(request.uri)) {
    const requested = request.uri;
    request.uri = `/${request.uri.split('/')[1]}/index.html`;
    console.log(`GET ${requested} => ${request.uri}`);
  } else {
    console.log(`Not rewriting URL ${request.uri}`);
  }

  callback(null, request);
};
