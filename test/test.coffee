# build time tests for plugmatic plugin
# see http://mochajs.org/

plugmatic = require '../client/plugmatic'
expect = require 'expect.js'

describe 'plugmatic plugin', ->

  # we default to less columns when there is lots to do
  lots = ['name', 'about', 'menu', 'bundled', 'installed']
  some = ['status', 'name', 'about', 'bundled', 'installed', 'published']

  describe 'columns', ->

    it 'handles null text', ->
      result = plugmatic.parse null
      expect(result.columns).to.eql lots

    it 'handles empty text', ->
      result = plugmatic.parse ''
      expect(result.columns).to.eql lots

    it 'handles some plugins', ->
      result = plugmatic.parse 'wiki-plugin-plugmatic'
      expect(result.columns).to.eql some

    it 'ignores invalid input', ->
      result = plugmatic.parse 'MUMBLE MENU'
      expect(result.columns).to.eql ['menu']

    it 'recognizes name', ->
      result = plugmatic.parse 'NAME'
      expect(result.columns).to.eql ['name']

    it 'recognizes status codes', ->
      result = plugmatic.parse 'STATUS MENU BUNDLED INSTALLED PUBLISHED'
      expect(result.columns).to.eql ['status', 'menu', 'bundled', 'installed', 'published']

    it 'recognizes counts', ->
      result = plugmatic.parse "ABOUT\nSERVICE"
      expect(result.columns).to.eql ['about', 'service']

    it 'ignores punctuation', ->
      result = plugmatic.parse '  NAME.'
      expect(result.columns).to.eql ['name']

    it 'asserts order witin a line', ->
      result = plugmatic.parse 'MENU PUBLISHED INSTALLED'
      expect(result.columns).to.eql ['menu', 'installed', 'published']

    it 'preservesrs order between lines', ->
      result = plugmatic.parse "MENU\nPUBLISHED\nINSTALLED"
      expect(result.columns).to.eql ['menu', 'published', 'installed']

  describe 'inventory', ->

    it 'recognizes plugins', ->
      result = plugmatic.parse 'wiki-plugin-method'
      expect(result.plugins).to.eql ['method']

    it 'recognizes multiple plugins', ->
      result = plugmatic.parse "wiki-plugin-method\nwiki-plugin-mumble"
      expect(result.plugins).to.eql ['method','mumble']
