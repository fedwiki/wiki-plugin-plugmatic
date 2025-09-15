export function browse (data,$item) {
  const install = data.install
  const result = $item.get(0).querySelector('p')
  const categories = ['format','data','other','system', 'option']
  const system = ['activity','changes','factory','flagmatic','journalmatic','future','image','paragraph','present','recycler','reference','register']

  result.innerHTML = categories.map(category => `
    <h3>${category}</h3>
    ${install
      .filter(plugin => {
        const have = plugin.factory?.category
        if (system.includes(plugin.plugin)) return (category == 'system')
        return (category == (have||'option'))
      })
      .map(format)
      .join("\n")}`
    )

  function format(plugin) {
    return `
      <details>
        <summary><a href=# style="text-decoration: none;">
          ${plugin.plugin}</a> — ${plugin.factory?.title??'<i style="color:#888">missing</i>'}
        </summary>
        ${details(plugin)}
      </details>
    `
  }

  function details(plugin) {
    function escape(markup) {
      return markup
        .replaceAll(/&/g, '&amp;')
        .replaceAll(/</g, '&lt;')
        .replaceAll(/>/g, '&gt;')
        .replaceAll(/\[\[(.*?)\]\]/g, '$1')
        .replaceAll(/\[.*? (.*?)\]/g, '$1')
    }
    const html = (plugin.pages||[]).map(page => `
      <p><a href=# style="text-decoration: none;" data-slug=${page.slug}>
          ${page.title}</a> — ${escape(page.synopsis??'')}
      </p>
    `).join("\n")
    const report = {
      author: plugin?.package.author,
      contributors: plugin?.package.contributors,
      version: plugin?.package.version,
      repository: plugin?.package.repository
    }
    return `
      <hr>
      ${html}
      <details><summary>more ...</summary>
        <pre>${JSON.stringify(report,null,2)}</pre>
      </details>
      <hr>`
  }

  for (const anchor of result.querySelectorAll('a')) {
    anchor.addEventListener('click',event => {
      event.preventDefault()
      const target = event.target
      const type = target.innerText.trim()
      const slug = target.dataset?.slug ?
        target.dataset.slug :
        `about-${type}-plugin`
      const $page = event.shiftKey ? null : $(target.closest('.page'))
      wiki.doInternalLink(slug, $page)
    })
  }
}