const whitelist = [
  'https://husdyrfag.io',
  'https://openfarm.io',
  new RegExp("http://localhost:\\d+"),
  new RegExp("https?://[^\\.]+\\.husdyrfag(-staging|-dev)?\\.io"),
  new RegExp("https?://[^\\.]+\\.openfarm(-staging|-dev)?\\.io")
];

function header(headers, name) {
  return headers[Object.keys(headers).filter(h => h.toLowerCase() === name)];
}

function whitelistedOrigin(origin) {
  return whitelist.filter(o => origin && origin.match(o))[0] && origin || whitelist[0];
}

exports.handler = (event, context) => {
  context.succeed({
    headers: {
      'Access-Control-Allow-Headers': 'Accept,Accept-Language,Content-Language,Content-Type,Authorization,x-correlation-id',
      'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS,POST',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Origin': whitelistedOrigin(header(event.headers, 'origin'))
    },
    statusCode: 204
  });
};
