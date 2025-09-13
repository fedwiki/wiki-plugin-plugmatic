/*
 * decaffeinate suggestions:

 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

const traffic = function (installed, published) {
  const color = {
    gray: '#ccc',
    red: '#f55',
    yellow: '#fb0',
    green: '#0e0',
  }

  if (installed != null && published != null) {
    if (installed === published) {
      return color.green
    } else {
      return color.yellow
    }
  } else {
    if (published != null) {
      return color.red
    } else {
      return color.gray
    }
  }
}

const escape = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

const expand = function (string) {
  const stashed = []
  const stash = function (text) {
    const here = stashed.length
    stashed.push(text)
    return `〖${here}〗`
  }
  const unstash = (match, digits) => stashed[+digits]
  const internal = function (match, name) {
    const slug = wiki.asSlug(name)
    const styling = name === name.trim() ? 'internal' : 'internal spaced'
    if (slug.length) {
      return stash(
        `<a class="${styling}" href="/${slug}.html" data-page-name="${slug}" title="view">${escape(name)}</a>`,
      )
    } else {
      return match
    }
  }
  const external = (match, href, protocol) =>
    stash(`"<a class="external" target="_blank" href="${href}" title="${href}" rel="nofollow">${escape(href)}</a>"`)
  string = string.replace(/〖(\d+)〗/g, '〖 $1 〗').replace(/\[\[([^\]]+)\]\]/gi, internal).replace(/"((http|https|ftp):.*?)"/gi, external)
  return escape(string).replace(/〖(\d+)〗/g, unstash)
}

const parse = function (text) {
  const result = { columns: [], plugins: [] }
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

const emit = function ($item, item) {
  const markup = parse(item.text)
  let dialog = null
  $item.append(`\
<p style="background-color:#eee;padding:15px;">
  loading plugin details
</p>\
`)

  const render = function (data) {
    let column = 'installed'
    const pub = name => data.publish.find(obj => obj.plugin === name)

    const format = function (markup, plugin, dependencies) {
      const name = plugin.plugin
      const months = plugin.birth ? ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5).toFixed(0) : ''
      const status = function () {
        const installed = plugin.package != null ? plugin.package.version : undefined
        const published = pub(name).npm?.version
        return traffic(installed, published)
      }

      const result = [`<tr class=row data-name=${plugin.plugin}>`]
      for (column of markup.columns) {
        result.push(
          (() => {
            switch (column) {
              case 'status':
                return `<td title=status style='text-align:center; color: ${status()}'>◉`
              case 'name':
                return `<td title=name> ${name}`
              case 'menu':
                return `<td title=menu> ${(plugin.factory != null ? plugin.factory.category : undefined) || ''}`
              case 'pages':
                return `<td title=pages style='text-align:center;'>${(plugin.pages != null ? plugin.pages.length : undefined) || ''}`
              case 'service':
                return `<td title=service style='text-align:center;'>${months}`
              case 'bundled':
                return `<td title=bundled> ${dependencies['wiki-plugin-' + name] || ''}`
              case 'installed':
                return `<td title=installed> ${(plugin.package != null ? plugin.package.version : undefined) || ''}`
              case 'published':
                return `<td title=published> ${pub(name).npm?.version || ''}`
            }
          })(),
        )
      }
      return result.join('\n')
    }

    const report = function (markup, plugins, dependencies) {
      let plugin
      const retrieve = function (name) {
        for (plugin of plugins) {
          if (plugin.plugin === name) {
            return plugin
          }
        }
        return { plugin: name }
      }
      const inventory = markup.plugins.length > 0 ? markup.plugins.map(retrieve) : plugins
      const head = (() => {
        const result1 = []
        for (column of markup.columns) {
          result1.push(`<td style='font-size:75%; color:gray;'>${column}`)
        }
        return result1
      })().join('\n')
      const result = (() => {
        const result2 = []
        for (let index = 0; index < inventory.length; index++) {
          plugin = inventory[index]
          result2.push(format(markup, plugin, dependencies))
        }
        return result2
      })().join('\n')
      return `<center> \
<p><img src="/favicon.png" width=16> <span style="color:gray;">${window.location.host}</span></p> \
<table style="width:100%;"><tr> ${head} ${result}</table> \
<button class=restart>restart</button> \
</center>`
    }

    const installer = function (row, npm) {
      let version
      if (npm == null) {
        return `<p>can't find wiki-plugin-${row.plugin} in <a href=//npmjs.com target=_blank>npmjs.com</a></p>`
      }
      const $row = $item.find(`table [data-name=${row.plugin}]`)
      const installed = function (update) {
        const index = data.install.indexOf(row)
        data.install[index] = row = update.row
        $row.find('[title=status]').css('color', traffic(update.installed, npm.version))
        $row.find('[title=menu]').text((row.factory != null ? row.factory.category : undefined) || '')
        $row.find('[title=pages]').text((row.pages != null ? row.pages.length : undefined) || '')
        $row.find('[title=service]').text('0')
        $row.find('[title=installed]').text((row.package != null ? row.package.version : undefined) || '')
        return $item.find('button.restart').removeAttr('disabled').show()
      }

      window.plugins.plugmatic.install = function (version) {
        $.ajax({
          type: 'POST',
          url: '/plugin/plugmatic/install',
          data: JSON.stringify({ version, plugin: row.plugin }),
          contentType: 'application/json; charset=utf-8',
          dataType: 'json',
          success: installed,
          error: trouble,
        })
        // http://stackoverflow.com/questions/2933826/how-to-close-jquery-dialog-within-the-dialog
        $row.find('[title=status]').css('color', 'white')
        return dialog.close()
      }

      const array = function (obj) {
        if (typeof obj === 'string') {
          return [obj]
        } else {
          return obj
        }
      }
      const choice = function (version) {
        const button = () => `<button onclick=window.plugins.plugmatic.install('${version}')> install </button>`
        return `<tr> <td> ${version} <td> ${version === (row.package != null ? row.package.version : undefined) ? 'installed' : button()}`
      }
      const choices = (() => {
        const result = []
        for (version of array(npm.versions).reverse()) {
          result.push(choice(version))
        }
        return result
      })()
      return `<h3>${npm.description}</h3> <p>Choose a version to install.</p> <table>${choices.join('\n')}`
    }

    const detail = function (name, done) {
      const row = data.install.find(obj => obj.plugin === name)
      const text = function (obj) {
        if (!obj) {
          return ''
        }
        return expand(obj).replace(/\n/g, '<br>')
      }
      const struct = function (obj) {
        if (!obj) {
          return ''
        }
        return `<pre>${expand(JSON.stringify(obj, null, '  '))}</pre>`
      }
      const pages = obj => `<p><b><a href=#>${obj.title}</a></b><br>${expand(obj.synopsis)}</p>`
      const birth = function (obj) {
        if (obj) {
          return new Date(obj).toString()
        } else {
          return 'built-in'
        }
      }
      const npmjs = more => $.getJSON(`/plugin/plugmatic/view/${name}`, more)
      switch (column) {
        case 'status':
          return npmjs(npm => done(installer(row, npm)))
        case 'name':
          return done(text(row.authors))
        case 'menu':
          return done(struct(row.factory))
        case 'pages':
          return done(row.pages.map(pages).join(''))
        case 'service':
          return done(birth(row.birth))
        case 'bundled':
          return done(struct(data.bundle.data.dependencies))
        case 'installed':
          return done(struct(row.package))
        case 'published':
          return done(struct(pub(name).npm || ''))
        default:
          return done('unexpected column')
      }
    }

    const showdetail = function (e) {
      const $parent = $(e.target).parent()
      const name = $parent.data('name')
      return detail(name, function (html) {
        console.log(column, name, $item, item)
        if (column === 'status') {
          // show dialog
          $item.find('dialog').remove()
          $item.append(`\
<dialog>
  ${html}
</dialog>\
`)
          dialog = $item.find('dialog')[0]
          console.log('dialog', dialog)
          return dialog.showModal()
        } else {
          // wiki.dialog "#{name} plugin #{column}", html || ''
          const pageKey = $item.parents('.page').data('key')
          const context = wiki.lineup.atKey(pageKey).getContext()
          const plugmaticDialog = window.open('/plugins/plugmatic/dialog/#', 'plugmatic', 'popup,height=600,width=800')
          if (plugmaticDialog.location.pathname !== '/plugins/plugmatic/dialog/') {
            return plugmaticDialog.addEventListener('load', event =>
              plugmaticDialog.postMessage(
                { column, title: `${name} plugin ${column}`, body: html || '', pageKey, context },
                window.origin,
              ),
            )
          } else {
            return plugmaticDialog.postMessage(
              { column, title: `${name} plugin ${column}`, body: html || '', pageKey, context },
              window.origin,
            )
          }
        }
      })
    }

    const more = function (e) {
      if (e.shiftKey) {
        return showdetail(e)
      }
    }

    const bright = function (e) {
      more(e)
      return $(e.currentTarget).css('background-color', '#f8f8f8')
    }
    const normal = e => $(e.currentTarget).css('background-color', '#eee')

    $item.find('p').html(report(markup, data.install, data.bundle.data.dependencies))
    $item.find('.row').on({
      mouseenter: bright,
      mouseleave: normal,
    })
    $item.find('p td').on('click', function (e) {
      column = $(e.target).attr('title')
      return showdetail(e)
    })
    return $item
      .find('button.restart')
      .hide()
      .on('click', function (e) {
        $item.find('button.restart').attr('disabled', 'disabled')
        return $.ajax({
          type: 'POST',
          url: '/plugin/plugmatic/restart',
          success() {},
          // poll for restart complete, then ...
          // $item.find('button.restart').hide()
          error: trouble,
        })
      })
  }

  var trouble = xhr =>
    $item.find('p').html((xhr.responseJSON != null ? xhr.responseJSON.error : undefined) || 'server error')

  if (markup.plugins.length) {
    return $.ajax({
      type: 'POST',
      url: '/plugin/plugmatic/plugins',
      data: JSON.stringify(markup),
      contentType: 'application/json; charset=utf-8',
      dataType: 'json',
      success: render,
      error: trouble,
    })
  } else {
    return $.ajax({
      url: '/plugin/plugmatic/plugins',
      dataType: 'json',
      success: render,
      error: trouble,
    })
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