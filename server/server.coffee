# plugmatic plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
glob = require 'glob'
async = require 'async'
jsonfile = require 'jsonfile'
https = require 'https'
exec = require('child_process').exec


github = (path, done) ->
  options =
    host: 'raw.githubusercontent.com'
    port: 443
    method: 'GET'
    path: path
  req = https.get options, (res) ->
    res.setEncoding 'utf8'
    data = ''
    res.on 'data', (d) ->
      data += d
    res.on 'end', () ->
      done data

# http://www.sebastianseilund.com/nodejs-async-in-practice

startServer = (params) ->
  app = params.app
  argv = params.argv
  bundle = null

  github '/fedwiki/wiki/master/package.json', (data) ->
    bundle =
      date: Date.now()
      data: JSON.parse data

  route = (endpoint) -> "/plugin/plugmatic/#{endpoint}"
  path = (file) -> "#{argv.packageDir}/#{file}"


  info = (file, done) ->
    plugin = file.slice 12    
    site = {plugin}

    birth = (cb) ->
      fs.stat path("#{file}/client/#{plugin}.js"), (err, stat) ->
        site.birth = stat?.birthtime?.getTime(); cb()
    pages = (cb) ->
      synopsis = (slug, cb2) -> 
        jsonfile.readFile path("#{file}/pages/#{slug}"), {throws:false}, (err, page) ->
          title = page.title || slug
          synopsis = page.story?[0]?.text || page.story?[1]?.text || 'empty'
          cb2 null, {title, synopsis}
      fs.readdir path("#{file}/pages"), (err, slugs) ->
        async.map slugs||[], synopsis, (err, pages) ->
          site.pages = pages; cb()
    packagejson = (cb) ->
      jsonfile.readFile path("#{file}/package.json"), {throws:false}, (err, packagejson) ->
        site.package = packagejson; cb()
    factory = (cb) ->
      jsonfile.readFile path("#{file}/factory.json"), {throws:false}, (err, factory) ->
        site.factory = factory; cb()
    authors = (cb) ->
      fs.readFile path("#{file}/AUTHORS.txt"), 'utf-8', (err, authors) ->
        site.authors = authors; cb()
    # persona = (cb) ->
    #   fs.readFile path("#{file}/status/persona.identity"),'utf8', (err, identity) ->
    #     site.persona = identity; cb()
    # openid = (cb) ->
    #   fs.readFile path("#{file}/status/open_id.identity"),'utf8', (err, identity) ->
    #     site.openid = identity; cb()
    async.series [birth,authors,packagejson,factory,pages], (err) ->
      done null, site

  view = (plugin, done) ->
    pkg = "wiki-plugin-#{plugin}"
    exec "npm view #{pkg} --json", (err, stdout, stderr) ->
      try npm = JSON.parse stdout
      done null, {plugin, pkg, npm}

  farm = (req, res, next) ->
    if argv.f
      next()
    else
      res.status(404).send {error: 'service requires farm mode'}

  admin = (req, res, next) ->
    if app.securityhandler.isAdmin(req)
      next()
    else
      admin = "none specified" unless argv.admin
      user = "not logged in" unless req.session?.passport?.user || req.session?.email || req.session?.friend
      res.status(403).send {error: 'service requires admin user', admin, user}

  app.get route('plugins'), (req, res) ->
    glob "wiki-plugin-*", {cwd: argv.packageDir}, (err, files) ->
      return res.e err if err
      async.map files||[], info, (err, install) ->
        return res.e err if err
        res.json {install, bundle}

  app.post route('plugins'), (req, res) ->
    payload = {bundle}

    installed = (cb) ->
      files = ("wiki-plugin-#{plugin}" for plugin in req.body.plugins||[])
      async.map files||[], info, (err, install) ->
        payload.install = install; cb()

    published = (cb) ->
      async.map req.body.plugins||[], view, (err, results) ->
        payload.publish = results; cb()
    
    async.parallel [installed, published], (err) ->
      res.json payload

  app.get route('view/:pkg'), (req, res) ->
    res.setHeader 'Content-Type', 'application/json'
    exec("npm view wiki-plugin-#{req.params.pkg} --json").stdout.pipe(res)

  app.post route('install'), admin, (req, res) ->
    pkg = "wiki-plugin-#{req.body.plugin}@#{req.body.version}"
    console.log "plugmatic installing #{pkg}"
    exec "npm install #{pkg} --json", (err, stdout, stderr) ->
      try npm = JSON.parse stdout
      if err
        res.status(400).json {error: 'server unable to install plugin', npm, stderr}
      else
        info "wiki-plugin-#{req.body.plugin}", (err, row) ->
          res.json {installed: req.body.version, npm, stderr, row}

  app.post route('restart'), admin, (req, res) ->
    console.log 'plugmatic exit to restart'
    res.sendStatus 200
    process.exit 0


module.exports = {startServer}
