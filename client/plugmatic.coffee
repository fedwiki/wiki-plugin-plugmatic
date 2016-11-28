
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

report = (plugins) ->
  result = []
  for plugin, index in plugins
    months = if plugin.birth 
      ((Date.now() - plugin.birth) / 1000 / 3600 / 24 / 31.5 ).toFixed(0)
    else
      ''
    result.push """
      <tr class=row>
      <td title=plugin> #{plugin.plugin}
      <td title=category> #{plugin.factory?.category || ''}
      <td title=about> #{plugin.pages?.length || ''}
      <td title=version> #{plugin.package?._id?.split(/@/)[1] || ''}
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

    detail = (e) ->
      $parent = $(e.target).parent()
      name = $parent.find('td:first').text().replace(/[^\w]/g,'')
      row = data.results.find (obj) -> obj.plugin == name
      text = (obj) -> return '' unless obj; (expand obj).replace(/\n/g,'<br>')
      struct = (obj) -> return '' unless obj; "<pre>#{expand JSON.stringify obj, null, '  '}</pre>"
      abouts = (obj) -> "<p><b><a href=#>#{obj.title}</a></b><br>#{obj.synopsis}</p>"
      birth = (obj) -> if obj then (new Date obj).toString() else 'built-in'
      html = switch column
        when 'plugin' then text row.authors
        when 'category' then struct row.factory
        when 'about' then row.pages.map(abouts).join('')
        when 'version' then struct row.package
        when 'months' then birth row.birth
        else 'unexpected column'
      wiki.dialog "#{name} plugin", html || ''

    more = (e) ->
     if e.shiftKey
       detail e

    bright = (e) -> more(e); $(e.currentTarget).css 'background-color', '#f8f8f8'
    normal = (e) -> $(e.currentTarget).css 'background-color', '#eee'

    $item.find('p').html report data.results
    $item.find('.row').hover bright, normal
    $item.find('p td').click (e) ->
      column = $(e.target).attr('title')
      detail e

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

