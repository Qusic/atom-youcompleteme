handler = require './handler'
utility = require './utility'

forceSemantic = false
lastPrefix = ''

processContext = ({editor, bufferPosition, prefix, activatedManually}) ->
  utility.getEditorData(editor).then ({filepath, contents, filetypes}) ->
    return {editor, filepath, contents, filetypes, bufferPosition, prefix, activatedManually}

fetchCompletions = ({editor, filepath, contents, filetypes, bufferPosition, prefix, activatedManually}) ->
  forceSemantic = false unless prefix.startsWith(lastPrefix) or lastPrefix.startsWith(prefix)
  forceSemantic = true if activatedManually
  lastPrefix = prefix
  parameters = utility.buildRequestParameters filepath, contents, filetypes, bufferPosition
  parameters.force_semantic = forceSemantic
  handler.request('POST', 'completions', parameters).then (response) ->
    completions = response?.completions or []
    startColumn = (response?.completion_start_column or (bufferPosition.column + 1)) - 1
    prefix = editor.getTextInBufferRange [[bufferPosition.row, startColumn], bufferPosition]
    return {completions, prefix, filetypes}

getSnippet = (completion) ->
    snippet = switch completion.kind
        when 'FUNCTION' then funcSnippet(completion)
        when 'MACRO' then macroSnippet(completion)
        else completion.insertion_text
    return snippet

funcSnippet = (completion) ->
    args = /\(\s*([^)]+?)\s*\)/.exec(completion.detailed_info)
    if (args) then arg = args[1].split(/\s*,\s*/)
    else arg = []
    snippet = "#{completion.insertion_text}("
    pos = 0
    for a in arg when pos < arg.length
        pos++
        snippet = snippet + "${#{pos}:#{a}}, "
    if(arg.length) then snippet = snippet.substring(0,snippet.length-2)+")"
    else snippet = snippet + ")"
    return snippet

macroSnippet = (completion) ->
    args = /\(.*\)/.exec(completion.detailed_info)
    if(args) then snippet = funcSnippet completion
    else snippet = "#{completion.insertion_text}"
    return snippet

convertCompletions = ({completions, prefix, filetypes}) ->
  converters =
    general: (completion) ->
      suggestion =
        text: completion.insertion_text
        snippet: getSnippet completion
        replacementPrefix: prefix
        displayText: completion.menu_text
        leftLabel: completion.extra_menu_info
        rightLabel: completion.kind
        description: completion.detailed_info
      suggestion.type = switch completion.kind
        when '[File]', '[Dir]', '[File&Dir]' then 'import'
        else null
      return suggestion

    clang: (completion) ->
      suggestion = converters.general completion
      suggestion.type = switch completion.kind
        when 'TYPE', 'STRUCT', 'ENUM' then 'type'
        when 'CLASS' then 'class'
        when 'MEMBER' then 'property'
        when 'FUNCTION' then 'function'
        when 'VARIABLE', 'PARAMETER' then 'variable'
        when 'MACRO' then 'constant'
        when 'NAMESPACE' then 'keyword'
        when 'UNKNOWN' then 'value'
        else suggestion.type
      return suggestion

    python: (completion) ->
      suggestion = converters.general completion
      suggestion.type = completion.display_string.substr(0, (completion.display_string.indexOf ': '))
      return suggestion

  converter = converters[(
    switch filetypes[0]
      when 'c', 'cpp', 'objc', 'objcpp' then 'clang'
      when 'python' then 'python'
      else 'general'
  )]

  completions.map converter

getCompletions = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchCompletions
    .then convertCompletions

module.exports = getCompletions
