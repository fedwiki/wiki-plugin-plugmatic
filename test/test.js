/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// build time tests for plugmatic plugin
// see http://mochajs.org/

import { plugmatic } from '../src/client/plugmatic.js'
import expect from 'expect.js'

describe('plugmatic plugin', function () {
  // we default to less columns when there is lots to do
  const lots = ['name', 'pages', 'menu', 'bundled', 'installed']
  const some = ['status', 'name', 'pages', 'bundled', 'installed', 'published']

  describe('columns', function () {
    it('handles null text', function () {
      const result = plugmatic.parse(null)
      return expect(result.columns).to.eql(lots)
    })

    it('handles empty text', function () {
      const result = plugmatic.parse('')
      return expect(result.columns).to.eql(lots)
    })

    it('handles some plugins', function () {
      const result = plugmatic.parse('wiki-plugin-plugmatic')
      return expect(result.columns).to.eql(some)
    })

    it('ignores invalid input', function () {
      const result = plugmatic.parse('MUMBLE MENU')
      return expect(result.columns).to.eql(['menu'])
    })

    it('recognizes name', function () {
      const result = plugmatic.parse('NAME')
      return expect(result.columns).to.eql(['name'])
    })

    it('recognizes status codes', function () {
      const result = plugmatic.parse('STATUS MENU BUNDLED INSTALLED PUBLISHED')
      return expect(result.columns).to.eql(['status', 'menu', 'bundled', 'installed', 'published'])
    })

    it('recognizes counts', function () {
      const result = plugmatic.parse('PAGES\nSERVICE')
      return expect(result.columns).to.eql(['pages', 'service'])
    })

    it('ignores punctuation', function () {
      const result = plugmatic.parse('  NAME.')
      return expect(result.columns).to.eql(['name'])
    })

    it('asserts order witin a line', function () {
      const result = plugmatic.parse('MENU PUBLISHED INSTALLED')
      return expect(result.columns).to.eql(['menu', 'installed', 'published'])
    })

    return it('preservesrs order between lines', function () {
      const result = plugmatic.parse('MENU\nPUBLISHED\nINSTALLED')
      return expect(result.columns).to.eql(['menu', 'published', 'installed'])
    })
  })

  return describe('inventory', function () {
    it('recognizes plugins', function () {
      const result = plugmatic.parse('wiki-plugin-method')
      return expect(result.plugins).to.eql(['method'])
    })

    return it('recognizes multiple plugins', function () {
      const result = plugmatic.parse('wiki-plugin-method\nwiki-plugin-mumble')
      return expect(result.plugins).to.eql(['method', 'mumble'])
    })
  })
})
