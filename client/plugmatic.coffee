
any = (array) ->
  array[Math.floor Math.random()*array.length]

traffic =
  gray:   '#ccc'
  red:    '#f77'
  yellow: '#ff7'
  green:  '#0f7'

escape = (text) ->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

expand = (string) ->
  stashed = []
  stash = (text) ->
    here = stashed.length
    stashed.push text
    "〖#{here}〗"
  unstash = (match, digits) ->
    stashed[+digits]
  external = (match, href, protocol) ->
    stash """\"<a class="external" target="_blank" href="#{href}" title="#{href}" rel="nofollow">#{escape href}</a>\""""
  string = string
    .replace /〖(\d+)〗/g, "〖 $1 〗"
    .replace /"((http|https|ftp):.*?)"/gi, external
  escape string
    .replace /〖(\d+)〗/g, unstash


parse = (text) ->
  result = {columns: [], plugins: []}
  lines = (text || '').split /\n+/
  for line in lines
    result.columns.push 'status'    if line.match /\STATUS\b/
    result.columns.push 'name'      if line.match /\bNAME\b/
    result.columns.push 'menu'      if line.match /\bMENU\b/
    result.columns.push 'about'     if line.match /\bABOUT\b/
    result.columns.push 'service'   if line.match /\bSERVICE\b/
    result.columns.push 'bundled'   if line.match /\bBUNDLED\b/
    result.columns.push 'installed' if line.match /\bINSTALLED\b/
    result.columns.push 'published' if line.match /\bPUBLISHED\b/
    result.plugins.push m[1]        if m = line.match /^wiki-plugin-(\w+)$/
  if result.columns.length == 0
    result.columns = if result.plugins.length == 0
      ['name', 'about', 'menu', 'bundled', 'installed']
    else
      ['status', 'name', 'about', 'bundled', 'installed', 'published']
  result


emit = ($item, item) ->
  markup = parse item.text
  $item.append """
    <p style="background-color:#eee;padding:15px;">
      loading plugin details
    </p>
  """

  render = (data) ->
    column = 'version'
    pub = (name) -> data.publish.find (obj) -> obj.plugin == name

    format = (markup, plugin, dependencies) ->
      name = plugin.plugin
      months = if plugin.birth
        ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5 ).toFixed(0)
      else
        ''
      status = ->
        installed = plugin.package?.version
        published = pub(name).npm?.version
        if installed? and published?
          if installed == published
            traffic.green
          else
            traffic.yellow
        else
          if published?
            traffic.red
          else
            traffic.gray

      result = ["<tr class=row data-name=#{plugin.plugin}>"]
      for column in markup.columns
        result.push switch column
          when 'status'    then "<td title=status style='color: #{status()}'>●"
          when 'name'      then "<td title=name> #{name}"
          when 'menu'      then "<td title=menu> #{plugin.factory?.category || ''}"
          when 'about'     then "<td title=about> #{plugin.pages?.length || ''}"
          when 'service'   then "<td title=service> #{months}"
          when 'bundled'   then "<td title=bundled> #{dependencies['wiki-plugin-'+name] || ''}"
          when 'installed' then "<td title=installed> #{plugin.package?.version || ''}"
          when 'published' then "<td title=published> #{pub(name).npm?.version || ''}"
      result.join "\n"

    report = (markup, plugins, dependencies) ->
      retrieve = (name) ->
        for plugin in plugins
          return plugin if plugin.plugin == name
        {plugin: name}
      inventory = if markup.plugins.length > 0
        markup.plugins.map retrieve
      else
        plugins
      head = ("<td style='font-size:75%; color:gray;'>#{column}" for column in markup.columns).join "\n"
      result = (format markup, plugin, dependencies for plugin, index in inventory).join "\n"
      "<table style=\"width:100%;\"><tr> #{head} #{result}</table>
      <center><button>restart</button></center>"

    install = (row, npm) ->
      return "<p>can't find this in <a href=//npmjs.com target=_blank>npmjs.com</a></p>" unless npm?
      window.plugins.plugmatic.install = (version) -> console.log 'installing', version, row, npm
      choice = (version) ->
        button = () -> "<button onclick=window.plugins.plugmatic.install('#{version}')> install </button>"
        "<tr> <td> #{version} <td> #{if version == row.package.version then 'installed' else button()}"
      choices = (choice(version) for version in npm.versions.reverse())
      "<h3>#{npm.description}</h3> <p>Choose a version to install.</p> <table>#{choices.join "\n"}"

    detail = (name, done) ->
      row = data.install.find (obj) -> obj.plugin == name
      text = (obj) -> return '' unless obj; (expand obj).replace(/\n/g,'<br>')
      struct = (obj) -> return '' unless obj; "<pre>#{expand JSON.stringify obj, null, '  '}</pre>"
      abouts = (obj) -> "<p><b><a href=#>#{obj.title}</a></b><br>#{obj.synopsis}</p>"
      birth = (obj) -> if obj then (new Date obj).toString() else 'built-in'
      npmjs = (more) -> $.getJSON "/plugin/plugmatic/view/#{name}", more
      switch column
        when 'status' then npmjs (npm) -> done install row, npm
        when 'name' then done text row.authors
        when 'menu' then done struct row.factory
        when 'about' then done row.pages.map(abouts).join('')
        when 'service' then done birth row.birth
        when 'bundled' then done struct data.bundle.data.dependencies
        when 'installed' then done struct row.package
        when 'published' then done struct pub(name).npm || ''
        else done 'unexpected column'

    showdetail = (e) ->
      $parent = $(e.target).parent()
      name = $parent.data('name')
      detail name, (html) ->
        wiki.dialog "#{name} plugin #{column}", html || ''

    more = (e) ->
     if e.shiftKey
       showdetail e

    bright = (e) -> more(e); $(e.currentTarget).css 'background-color', '#f8f8f8'
    normal = (e) -> $(e.currentTarget).css 'background-color', '#eee'

    $item.find('p').html report markup, data.install, data.bundle.data.dependencies
    $item.find('.row').hover bright, normal
    $item.find('p td').click (e) ->
      column = $(e.target).attr('title')
      showdetail e
    $item.find('button').click (e) ->
      $.ajax
        type: "POST"
        url: '/plugin/plugmatic/restart'
        success: -> console.log('success')
        error: trouble

  trouble = (xhr) -> 
    $item.find('p').html xhr.responseJSON?.error || 'server error'

  if markup.plugins.length
    $.ajax
      type: 'POST'
      url: '/plugin/plugmatic/plugins'
      data: JSON.stringify(markup)
      contentType: "application/json; charset=utf-8"
      dataType: 'json'
      success: render
      error: trouble
  else
    $.ajax
      url: '/plugin/plugmatic/plugins'
      dataType: 'json'
      success: render
      error: trouble

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.plugmatic = {emit, bind} if window?
module.exports = {parse} if module?
