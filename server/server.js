/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// plugmatic plugin, server-side component
// These handlers are launched with the wiki server.

import * as fs from 'node:fs'
import { glob } from 'glob'
import * as asyncLib from 'async'
import jsonfile from 'jsonfile'
import https from 'node:https'
import { execFile } from 'node:child_process'

const github = function (path, done) {
  const options = {
    host: 'raw.githubusercontent.com',
    port: 443,
    method: 'GET',
    path,
  }
  try {
    const req = https.get(options, function (res) {
      res.setEncoding('utf8')
      let data = ''
      res.on('error', () => done(null))
      res.on('timeout', () => done(null))
      res.on('data', d => (data += d))
      return res.on('end', () => done(data))
    })
    return req.on('error', () => done(null))
  } catch (e) {
    return done(null)
  }
}

// http://www.sebastianseilund.com/nodejs-async-in-practice

const startServer = function (params) {
  const { app } = params
  const { argv } = params
  let bundle = null

  github(
    '/fedwiki/wiki/master/package.json',
    data =>
      (bundle = {
        date: Date.now(),
        data: JSON.parse(data || '{"dependencies":{}}'),
      }),
  )

  const route = endpoint => `/plugin/plugmatic/${endpoint}`
  const path = file => `${argv.packageDir}/${file}`

  const info = function (file, done) {
    const plugin = file.slice(12)
    const site = { plugin }

    const birth = cb =>
      fs.stat(path(`${file}/client/${plugin}.js`), function (err, stat) {
        site.birth = stat?.birthtime?.getTime()
        return cb()
      })
    const pages = function (cb) {
      var synopsis = (slug, cb2) =>
        jsonfile.readFile(path(`${file}/pages/${slug}`), { throws: false }, function (err, page) {
          const title = page.title || slug
          synopsis = page.story?.[0]?.text || page.story?.[1]?.text || 'empty'
          return cb2(null, { file, slug, title, synopsis })
        })
      return fs.readdir(path(`${file}/pages`), (err, slugs) =>
        asyncLib.map(slugs || [], synopsis, function (err, pages) {
          site.pages = pages
          return cb()
        }),
      )
    }
    const packagejson = cb =>
      jsonfile.readFile(path(`${file}/package.json`), { throws: false }, function (err, packagejson) {
        site.package = packagejson
        return cb()
      })
    const factory = cb =>
      jsonfile.readFile(path(`${file}/factory.json`), { throws: false }, function (err, factory) {
        site.factory = factory
        return cb()
      })
    const authors = cb =>
      fs.readFile(path(`${file}/AUTHORS.txt`), 'utf-8', function (err, authors) {
        site.authors = authors
        return cb()
      })
    // persona = (cb) ->
    //   fs.readFile path("#{file}/status/persona.identity"),'utf8', (err, identity) ->
    //     site.persona = identity; cb()
    // openid = (cb) ->
    //   fs.readFile path("#{file}/status/open_id.identity"),'utf8', (err, identity) ->
    //     site.openid = identity; cb()
    return asyncLib.series([birth, authors, packagejson, factory, pages], err => done(null, site))
  }

  const plugmap = done =>
    glob('wiki-plugin-*', { cwd: argv.packageDir }, function (err, files) {
      if (err) {
        return done(err, null)
      }
      return asyncLib.map(files || [], info, function (err, install) {
        if (err) {
          return done(err, null)
        }
        return done(null, install)
      })
    })

  const view = function (plugin, done) {
    if (/^\w+$/.test(plugin)) {
      const pkg = `wiki-plugin-${plugin}`
      return execFile('npm', ['view', `${pkg}`, '--json'], function (err, stdout, stderr) {
        let npm
        try {
          npm = JSON.parse(stdout)
        } catch (error) {
          // ignore parse errors
        }
        return done(null, { plugin, pkg, npm })
      })
    }
  }

  const farm = function (req, res, next) {
    if (argv.f) {
      return next()
    } else {
      return res.status(404).send({ error: 'service requires farm mode' })
    }
  }

  var admin = function (req, res, next) {
    if (app.securityhandler.isAdmin(req)) {
      return next()
    } else {
      let user
      if (!argv.admin) {
        admin = 'none specified'
      }
      if (!req.session?.passport?.user && !req.session?.email && !req.session?.friend) {
        user = 'not logged in'
      }
      return res.status(403).send({ error: 'service requires admin user', admin, user })
    }
  }

  app.get(route('page/:slug.json'), (req, res) =>
    plugmap(function (err, install) {
      for (var i of Array.from(install)) {
        for (var p of Array.from(i.pages)) {
          if (p.slug === req.params.slug) {
            return jsonfile.readFile(path(`${p.file}/pages/${p.slug}`), { throws: false }, (err, page) =>
              res.json(page),
            )
          }
        }
      }
      return res.sendStatus(404)
    }),
  )

  app.get(route('file/:file/slug/:slug'), (req, res) =>
    jsonfile.readFile(path(`${req.params.file}/pages/${req.params.slug}`), { throws: false }, function (err, page) {
      if (err) {
        return res.sendStatus(404)
      } else {
        return res.json(page)
      }
    }),
  )

  app.get(route('sitemap.json'), (req, res) =>
    plugmap(
      (
        err,
        install, // http://stackoverflow.com/a/4631593
      ) => res.json([].concat(...Array.from(Array.from(install).map(i => i.pages) || []))),
    ),
  )

  app.get(route('plugins'), (req, res) =>
    glob('wiki-plugin-*', { cwd: argv.packageDir }, function (err, files) {
      if (err) {
        return res.e(err)
      }
      return asyncLib.map(files || [], info, function (err, install) {
        if (err) {
          return res.e(err)
        }
        return res.json({ install, bundle })
      })
    }),
  )

  app.post(route('plugins'), function (req, res) {
    const payload = { bundle }

    const installed = function (cb) {
      const files = Array.from(req.body.plugins || []).map(plugin => `wiki-plugin-${plugin}`)
      return asyncLib.map(files || [], info, function (err, install) {
        payload.install = install
        return cb()
      })
    }

    const published = cb =>
      asyncLib.map(req.body.plugins || [], view, function (err, results) {
        payload.publish = results
        return cb()
      })

    return asyncLib.parallel([installed, published], err => res.json(payload))
  })

  app.get(route('view/:pkg'), function (req, res) {
    if (/^\w+$/.test(req.params.pkg)) {
      const pkg = `wiki-plugin-${req.params.pkg}`
      res.setHeader('Content-Type', 'application/json')
      return execFile('npm', ['view', `${pkg}`, '--json']).stdout.pipe(res)
    }
  })

  app.post(route('install'), admin, function (req, res) {
    if (/^\w+$/.test(req.body.plugin) && /^[\w.-]+$/.test(req.body.version)) {
      const pkg = `wiki-plugin-${req.body.plugin}@${req.body.version}`
      console.log(`plugmatic installing ${pkg}`)
      return execFile(
        'npm',
        ['install', `${pkg}`, '--json'],
        { cwd: argv.packageDir + '/..' },
        function (err, stdout, stderr) {
          let npm
          try {
            npm = JSON.parse(stdout)
          } catch (error) {
            // ignore parse errors
          }
          if (err) {
            return res.status(400).json({ error: 'server unable to install plugin', npm, stderr })
          } else {
            return info(`wiki-plugin-${req.body.plugin}`, (err, row) =>
              res.json({ installed: req.body.version, npm, stderr, row }),
            )
          }
        },
      )
    }
  })

  return app.post(route('restart'), admin, function (req, res) {
    console.log('plugmatic exit to restart')
    res.sendStatus(200)
    return process.exit(0)
  })
}

export { startServer }
