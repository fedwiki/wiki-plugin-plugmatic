# plugmatic plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
glob = require 'glob'
async = require 'async'
jsonfile = require 'jsonfile'

# http://www.sebastianseilund.com/nodejs-async-in-practice

startServer = (params) ->
  app = params.app
  argv = params.argv

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
      # extract the plugin name from the name of the directory it's installed in
      # files = files.map (file) -> file.slice(12)
      # res.send(files)
      async.map files||[], info, (err, results) ->
        return res.e err if err
        res.json {results}

module.exports = {startServer}
