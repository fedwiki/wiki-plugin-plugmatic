
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

report = (plugins, dependencies) ->
  console.log 'dependencies', dependencies
  result = []
  for plugin, index in plugins
    months = if plugin.birth 
      ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5 ).toFixed(0)
    else
      ''
    result.push """
      <tr class=row>
      <td title=authors> #{plugin.plugin}
      <td title=category> #{plugin.factory?.category || ''}
      <td title=about> #{plugin.pages?.length || ''}
      <td title=version> #{plugin.package?._id?.split(/@/)[1] || ''}
      <td title=current> #{dependencies["wiki-plugin-#{plugin.plugin}"] || ''}
      <td title="months"> #{months}
    """
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
        when 'category' then done struct row.factory
        when 'about' then done row.pages.map(abouts).join('')
        when 'version' then done struct row.package
        when 'current' then $.getJSON "/plugin/plugmatic/view/#{name}", (data) -> done struct data
        when 'months' then done birth row.birth
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

    $item.find('p').html report data.results, data.pub.data.dependencies
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
module.exports = {expand} if module?

