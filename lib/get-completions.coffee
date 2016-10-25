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

convertCompletions = ({completions, prefix, filetypes}) ->
  converter = (filetype) ->
    general = (completion) ->
      suggestion =
        text: completion.insertion_text
        replacementPrefix: prefix
        displayText: completion.menu_text
        leftLabel: completion.extra_menu_info.replace(/(^\[|\]$)/g, '')
        rightLabel: completion.kind
        description: completion.detailed_info
      suggestion.type = switch completion.extra_menu_info
        when '[File]', '[Dir]', '[File&Dir]' then 'import'
        when '[ID]' then 'tag'
        else null
      return suggestion

    clang = (completion) ->
      suggestion = general completion
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

    switch filetype
      when 'c', 'cpp', 'objc', 'objcpp' then clang
      else general

  completions.map converter filetypes[0]

getCompletions = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchCompletions
    .then convertCompletions

module.exports = getCompletions
