/*
 * decaffeinate suggestions:

 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import { render } from './render.js'
import { browse } from './browse.js'

const parse = function (text) {
  const result = { columns: [], plugins: [], features: [] }
  const lines = (text || '').split(/\n+/)
  for (var line of lines) {
    var m
    if (line.match(/\bSTATUS\b/)) {
      result.columns.push('status')
    }
    if (line.match(/\bNAME\b/)) {
      result.columns.push('name')
    }
    if (line.match(/\bMENU\b/)) {
      result.columns.push('menu')
    }
    if (line.match(/\bPAGES\b/)) {
      result.columns.push('pages')
    }
    if (line.match(/\bSERVICE\b/)) {
      result.columns.push('service')
    }
    if (line.match(/\bBUNDLED\b/)) {
      result.columns.push('bundled')
    }
    if (line.match(/\bINSTALLED\b/)) {
      result.columns.push('installed')
    }
    if (line.match(/\bPUBLISHED\b/)) {
      result.columns.push('published')
    }

    if (line.match(/\bBROWSE\b/)) {
      result.features.push('browse')
    }

    if ((m = line.match(/^wiki-plugin-(\w+)$/))) {
      result.plugins.push(m[1])
    }
  }
  if (result.columns.length === 0) {
    result.columns =
      result.plugins.length === 0
        ? ['name', 'pages', 'menu', 'bundled', 'installed']
        : ['status', 'name', 'pages', 'bundled', 'installed', 'published']
  }
  return result
}

const emit = async function ($item, item) {
  const markup = parse(item.text)
  $item.append(`\
<p style="background-color:#eee;padding:15px;">
  loading plugin details
</p>\
`)

  const renderproxy = data => {
    if (markup.features.includes('browse')) browse(data, $item)
    else render(data, $item, markup)
  }

  try {
    if (markup.plugins.length) {
      const options = {
        method: 'POST',
        body: JSON.stringify(markup),
        headers: { 'Content-Type': 'application/json' },
      }
      renderproxy(await fetch('/plugin/plugmatic/plugins', options).then(res => res.json()))
    } else {
      renderproxy(await fetch('/plugin/plugmatic/plugins').then(res => res.json()))
    }
  } catch (err) {
    $item.find('p').html('server error')
  }
}

const bind = ($item, item) => $item.on('dblclick', () => wiki.textEditor($item, item))

const plugmaticListener = function (event) {
  if (!event.source.opener || event.source.location.pathname !== '/plugins/plugmatic/dialog/') {
    return
  }
  console.log('plugmatic listerner', event)

  const { data } = event

  const { action } = data

  switch (action) {
    case 'doInternalLink':
      var val = data.keepLineup,
        keepLineup = val != null ? val : false,
        val1 = data.pageKey,
        pageKey = val1 != null ? val1 : null,
        val2 = data.title,
        title = val2 != null ? val2 : null,
        val3 = data.context,
        context = val3 != null ? val3 : null
      var $page = null
      if (pageKey !== null) {
        $page = keepLineup ? null : $('.page').filter((i, el) => $(el).data('key') === pageKey)
      }
      wiki.pageHandler.context = context
      wiki.doInternalLink(title, $page)
      break
    default:
      return console.error({ where: 'plugmaticListener', message: 'unknown action', data })
  }
}

if (typeof window !== 'undefined' && window !== null) {
  if (typeof window.plugmaticListener === 'undefined' || window.plugmaticListener === null) {
    console.log('*** Plugmatic - Adding Message Listener')
    window.plugmaticListener = plugmaticListener
    window.addEventListener('message', plugmaticListener)
  }
}

if (typeof window !== 'undefined' && window !== null) {
  window.plugins.plugmatic = { emit, bind }
}
if (typeof module !== 'undefined' && module !== null) {
  module.exports = { parse }
}
