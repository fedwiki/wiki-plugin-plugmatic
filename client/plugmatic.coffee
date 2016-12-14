
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
    result.columns.push 'name'    if line.match /\bNAME\b/
    result.columns.push 'factory' if line.match /\bFACTORY\b/
    result.columns.push 'pages'   if line.match /\bPAGES\b/
    result.columns.push 'version' if line.match /\bVERSION\b/
    result.columns.push 'current' if line.match /\bCURRENT\b/
    result.columns.push 'months'  if line.match /\bMONTHS\b/
    result.plugins.push m[1]      if m = line.match /^wiki-plugin-(\w+)$/
  result

format = (markup, plugin, dependencies) ->
  months = if plugin.birth
    ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5 ).toFixed(0)
  else
    ''
  result = ["<tr class=row>"]
  for column in markup.columns
    result.push switch column
      when 'name' then "<td title=authors> #{plugin.plugin}"
      when 'factory' then "<td title='factory category'> #{plugin.factory?.category || ''}"
      when 'pages' then "<td title='about pages'> #{plugin.pages?.length || ''}"
      when 'version' then "<td title=version> #{plugin.package?._id?.split(/@/)[1] || ''}"
      when 'current' then "<td title=current> #{dependencies['wiki-plugin-'+plugin.plugin] || ''}"
      when 'months' then "<td title='months old'> #{months}"
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
        when 'authors' then done text row.authors
        when 'factory category' then done struct row.factory
        when 'about pages' then done row.pages.map(abouts).join('')
        when 'version' then done struct row.package
        when 'current' then $.getJSON "/plugin/plugmatic/view/#{name}", (data) -> done struct data
        when 'months old' then done birth row.birth
        else done 'unexpected column'

    showdetail = (e) ->
      $parent = $(e.target).parent()
      name = $parent.find('td:first').text().replace(/[^\w]/g,'')
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

