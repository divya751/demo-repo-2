const {createLogger, format, transports} = require('winston');
const {combine, timestamp, splat, json} = format;

module.exports = (serviceName = 'undefined') => {
  return createLogger({
    format: combine(
      timestamp(),
      splat(),
      format(logMsg => {
        logMsg.service = serviceName;
        return logMsg;
      })(),
      json()
    ),
    transports: [
      new transports.Console()
    ]
  });
};