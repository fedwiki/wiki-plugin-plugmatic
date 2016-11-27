# build time tests for plugmatic plugin
# see http://mochajs.org/

plugmatic = require '../client/plugmatic'
expect = require 'expect.js'

describe 'plugmatic plugin', ->

  describe 'expand', ->

    it 'can make itallic', ->
      result = plugmatic.expand 'hello *world*'
      expect(result).to.be 'hello <i>world</i>'
