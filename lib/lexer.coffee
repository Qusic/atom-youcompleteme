findCharIgnoreInScope = (s, c, left, right, bidx = 0, eidx = s.length) ->
  lvl = 0
  for i in [bidx...eidx]
    t = s.charAt i
    if lvl is 0 and t is c
      return i
    if t is left
      lvl++
    else if t is right
      lvl--
  return -1

findLastCharIgnoreInScope = (s, c, left, right, bidx = 0, eidx = s.length) ->
  lvl = 0
  for i in [eidx - 1..bidx] by -1
    t = s.charAt i
    if lvl is 0 and t is c
      return i
    if t is right
      lvl++
    else if t is left
      lvl--
  return -1

clangFunctionInfoFromDetailed = (detailed) ->
  detailed.split('\n')[...-1].map (f) ->
    # TODO: objc
    # if f.indexOf ':('
    # param part rigth parenthese
    c2 = f.lastIndexOf ')'
    # param part left parenthese
    c1 = findLastCharIgnoreInScope f, '(', '(', ')', 0, c2
    # space before name
    c0 = findLastCharIgnoreInScope f, ' ', '<', '>', 0, c1
    r =
      ret: f.substring 0, c0
      name: f.substring c0 + 1, c1
    if c2 - c1 > 3
      # have param
      r.args = []
      p = c1 + 2
      q = 0
      (
        q = findCharIgnoreInScope f, ',', '<', '>', p, c2 - 1
        unless q is -1
          r.args.push f.substring p, q
          p = q + 2
      ) until q is -1
      r.args.push f.substring p, c2 - 1
    # split template param
    if f.charAt(c1 - 1) is '>'
      p = r.name.indexOf '<'
      r.tpl = r.name.substring(p + 1, r.name.length - 1).split(', ')
      r.name = r.name.substring 0, p
    # split class name
    p = r.name.lastIndexOf '::'
    unless p is -1
      r.cls = r.name.substring 0, p
      r.name = r.name.substring p + 2
    return r

clangFunctionLexer = (completion, prefix) ->
  clangFunctionInfoFromDetailed(completion.detailed_info).map (info) ->
    displayText = info.name
    text = info.name
    placeholderIndex = 1
    if info.tpl?
      displayText += "<#{info.tpl.join(', ')}>"
      text += '<' + info.tpl.map((chunk) -> "${#{placeholderIndex++}:#{chunk}}").join(', ') + '>'
    if info.args?
      displayText += "(#{info.args.join(', ')})"
      text += '(' + info.args.map((chunk) -> "${#{placeholderIndex++}:#{chunk}}").join(', ') + ')'
    unless info.tpl? or info.args?
      displayText += '()'
      text += '()'
    r =
      displayText: displayText
      replacementPrefix: prefix
      leftLabel: info.ret
      rightLabel: info.cls
      description: completion.extra_data.doc_string if completion.extra_data?
      type: 'function'
    unless info.tpl? or info.args?
      r.text = text
    else
      r.snippet = text
    if r.displayText.length > 54
      tmp = r.displayText
      tmp += "\n#{r.description}" if r.description?
      r.description = tmp
    return r

clangGeneralPlus = (completion, suggestion) ->
  suggestion.description = completion.extra_data.doc_string if completion.extra_data?
  suggestion.rightLabel = ''
  p = completion.menu_text?.lastIndexOf '::'
  if p? and not p is -1 and not p is completion.menu_text.length - 2
    suggestion.displayText = completion.menu_text.substring p + 2
    suggestion.rightLabel = completion.menu_text.substring 0, p
  infos = completion.detailed_info?.split('\n')
  if infos? and infos.length > 2
    tmp = infos[1...-1].join('\n')
    tmp += "\n#{suggestion.description}" if suggestion.description?
    suggestion.description = tmp
  return [suggestion]

module.exports =
  clangFunctionLexer: clangFunctionLexer
  clangGeneralPlus: clangGeneralPlus
