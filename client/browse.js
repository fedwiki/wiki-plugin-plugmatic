export function browse (data,$item) {
  const install = data.install
  const result = $item.get(0).querySelector('p')
  const categories = ['format','data','other','system', 'option']
  const system = ['activity','changes','factory','flagmatic','journalmatic','future','image','paragraph','present','recycler','reference','register']
  result.innerHTML = "<b>hello world</b>"
}