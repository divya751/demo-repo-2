/*global describe, it*/
const whitelist = require('../src/whitelist-cors').handler;
const assert = require('assert');

function exercise(event) {
  let res = null;
  const context = {succeed: r => res = r};
  whitelist(event, context);
  return res;
}

function allowOrigin(event) {
  return exercise(event).headers['Access-Control-Allow-Origin'];
}

describe('Whitelisting CORS requests', () => {
  it('Uses default for unrecognized domain', () => {
    assert.equal(allowOrigin({headers: {Origin: 'http://localhost'}}), 'https://husdyrfag.io');
    assert.equal(allowOrigin({headers: {Origin: 'http://vg.no'}}), 'https://husdyrfag.io');
  });

  it('Sets CORS host to matching host', () => {
    assert.equal(allowOrigin({headers: {Origin: 'http://localhost:8080'}}), 'http://localhost:8080');
  });

  it('Uses default for matched domain but unmatched protocol', () => {
    assert.equal(allowOrigin({headers: {Origin: 'http://husdyrfag.io'}}), 'https://husdyrfag.io');
  });

  it('Allows http for sub-domains', () => {
    assert.equal(allowOrigin({headers: {Origin: 'http://web.husdyrfag.io'}}), 'http://web.husdyrfag.io');
  });

  it('Recognizes the default domain over HTTPS', () => {
    assert.equal(allowOrigin({headers: {Origin: 'https://husdyrfag.io'}}), 'https://husdyrfag.io');
  });

  it('Allows sub-domains over HTTPS', () => {
    assert.equal(allowOrigin({headers: {Origin: 'https://web-dev.husdyrfag.io'}}), 'https://web-dev.husdyrfag.io');
  });

  it('Allows dev sub-domains over HTTPS', () => {
    assert.equal(allowOrigin({headers: {Origin: 'https://web.husdyrfag-dev.io'}}), 'https://web.husdyrfag-dev.io');
  });

  it('Allows staging sub-domains over HTTPS', () => {
    assert.equal(allowOrigin({headers: {Origin: 'https://web.husdyrfag-staging.io'}}), 'https://web.husdyrfag-staging.io');
  });
});
