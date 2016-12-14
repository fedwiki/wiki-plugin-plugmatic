# build time tests for plugmatic plugin
# see http://mochajs.org/

plugmatic = require '../client/plugmatic'
expect = require 'expect.js'

describe 'plugmatic plugin', ->

  describe 'columns', ->

    it 'ignores invalid input', ->
      result = plugmatic.parse 'mumble'
      expect(result.columns).to.eql []

    it 'recognizes name', ->
      result = plugmatic.parse 'NAME'
      expect(result.columns).to.eql ['name']

    it 'recognizes status codes', ->
      result = plugmatic.parse 'FACTORY VERSION CURRENT'
      expect(result.columns).to.eql ['factory', 'version', 'current']

    it 'recognizes counts', ->
      result = plugmatic.parse 'PAGES\nMONTHS'
      expect(result.columns).to.eql ['pages', 'months']

    it 'ignores punctuation', ->
      result = plugmatic.parse '  NAME.'
      expect(result.columns).to.eql ['name']

    it 'asserts order witin a line', ->
      result = plugmatic.parse 'FACTORY CURRENT VERSION'
      expect(result.columns).to.eql ['factory', 'version', 'current']

    it 'preservesrs order between lines', ->
      result = plugmatic.parse 'FACTORY\nCURRENT\nVERSION'
      expect(result.columns).to.eql ['factory', 'current', 'version']

