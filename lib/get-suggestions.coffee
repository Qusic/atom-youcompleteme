handler = require './handler'
utility = require './utility'

processContext = ({editor, scopeDescriptor, bufferPosition, prefix, activatedManually}) ->
  utility.getEditorData(editor, scopeDescriptor).then ({filepath, contents, filetypes}) ->
    return {editor, filepath, contents, filetypes, bufferPosition, activatedManually}

fetchCompletions = ({editor, filepath, contents, filetypes, bufferPosition, activatedManually}) ->
  parameters = utility.buildRequestParameters filepath, contents, filetypes, bufferPosition
  parameters.force_semantic = true if activatedManually
  handler.request('POST', 'completions', parameters).then (response) ->
    completions = response?.completions or []
    startColumn = (response?.completion_start_column or (bufferPosition.column + 1)) - 1
    prefix = editor.getTextInBufferRange [[bufferPosition.row, startColumn], bufferPosition]
    return {completions, prefix, filetypes}

convertCompletions = ({completions, prefix, filetypes}) ->
  converters =
    general: (completion) ->
      suggestion =
        text: completion.insertion_text
        replacementPrefix: prefix
        displayText: completion.menu_text
        leftLabel: completion.extra_menu_info
        rightLabel: completion.kind
        description: null
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

  formatter = (suggestion) ->
    # if suggestion.leftLabel?.length > 20
      # suggestion.leftLabel = "#{suggestion.leftLabel.substr 0, 20}…"
    return suggestion

  converter = converters[(
    switch filetypes[0]
      when 'c', 'cpp', 'objc', 'objcpp' then 'clang'
      when 'python' then 'python'
      else 'general'
  )]

  completions.map (completion) -> formatter converter completion

getSuggestions = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchCompletions
    .then convertCompletions

module.exports = getSuggestions
