/*global describe, it*/
const {assert} = require('chai');
const {handler} = require('../url-rewrite');

const rewrite = uri => {
  let res;
  handler({Records: [{cf: {request: {uri, method: 'GET'}}}]}, {}, (err, result) => res = result);
  return res;
};

describe('URL rewriter', () => {
  it('rewrites directory in app to index.html', () => {
    assert.equal(rewrite('/tanklapp/mappe/').uri, '/tanklapp/index.html');
  });

  it('preserves properties on the event in the response', () => {
    assert.equal(rewrite('/tanklapp/mappe/').method, 'GET');
  });

  it('rewrites app root to index file', () => {
    assert.equal(rewrite('/tanklapp/').uri, '/tanklapp/index.html');
  });

  it('rewrites nested directory to root index file', () => {
    assert.equal(rewrite('/tanklapp/some/dir/here/').uri, '/tanklapp/index.html');
  });

  it('does not rewrite html file requests', () => {
    assert.equal(rewrite('/tanklapp/index.html').uri, '/tanklapp/index.html');
  });

  it('does not rewrite png requests', () => {
    assert.equal(rewrite('/tanklapp/images/logo.png').uri, '/tanklapp/images/logo.png');
  });

  it('does not rewrite css requests', () => {
    assert.equal(rewrite('/tanklapp/app.css').uri, '/tanklapp/app.css');
  });
});
