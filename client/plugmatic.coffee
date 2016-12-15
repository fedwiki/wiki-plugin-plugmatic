
any = (array) ->
  array[Math.floor Math.random()*array.length]

traffic =
  gray:   '#ccc'
  red:    '#f77'
  yellow: '#ff7'
  green:  '#0f7'

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

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
  result

format = (markup, plugin, dependencies) ->
  months = if plugin.birth
    ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5 ).toFixed(0)
  else
    ''
  result = ["<tr class=row data-name=#{plugin.plugin}>"]
  for column in markup.columns
    result.push switch column
      when 'status'    then "<td title=status><span style='color: #{traffic.gray}'>●</span>"
      when 'name'      then "<td title=name> #{plugin.plugin}"
      when 'menu'      then "<td title=menu> #{plugin.factory?.category || ''}"
      when 'about'     then "<td title=about> #{plugin.pages?.length || ''}"
      when 'service'   then "<td title=service> #{months}"
      when 'bundled'   then "<td title=bundled> #{plugin.package?._id?.split(/@/)[1] || ''}"
      when 'installed' then "<td title=installed> #{dependencies['wiki-plugin-'+plugin.plugin] || ''}"
      when 'published' then "<td title=published> #{dependencies['wiki-plugin-'+plugin.plugin] || ''}"
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
  result = (format markup, plugin, dependencies for plugin, index in inventory)
  "<table style=\"width:100%;\">#{result.join "\n"}</table>"

emit = ($item, item) ->
  $item.append """
    <p style="background-color:#eee;padding:15px;">
      loading plugin details
    </p>
  """

  render = (data) ->
    column = 'version'

    detail = (name, done) ->
      row = data.results.find (obj) -> obj.plugin == name
      text = (obj) -> return '' unless obj; (expand obj).replace(/\n/g,'<br>')
      struct = (obj) -> return '' unless obj; "<pre>#{expand JSON.stringify obj, null, '  '}</pre>"
      abouts = (obj) -> "<p><b><a href=#>#{obj.title}</a></b><br>#{obj.synopsis}</p>"
      birth = (obj) -> if obj then (new Date obj).toString() else 'built-in'
      switch column
        when 'status' then done text row.authors
        when 'name' then done text row.authors
        when 'menu' then done struct row.factory
        when 'about' then done row.pages.map(abouts).join('')
        when 'service' then done birth row.birth
        when 'bundled' then done struct row.package
        when 'installed' then done struct row.package
        when 'published' then $.getJSON "/plugin/plugmatic/view/#{name}", (data) -> done struct data
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

    markup = parse item.text
    $item.find('p').html report markup, data.results, data.pub.data.dependencies
    $item.find('.row').hover bright, normal
    $item.find('p td').click (e) ->
      column = $(e.target).attr('title')
      showdetail e

  trouble = (xhr) -> 
    $item.find('p').html xhr.responseJSON?.error || 'server error'

  $.ajax
    url: '/plugin/plugmatic/plugins'
    dataType: 'json'
    success: render
    error: trouble

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.plugmatic = {emit, bind} if window?
module.exports = {parse} if module?

