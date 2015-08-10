handler = require './handler'
utility = require './utility'

processContext = ({editor, scopeDescriptor, bufferPosition}) ->
  utility.getEditorData(editor, scopeDescriptor).then ({filepath, contents, filetypes}) ->
    return {editor, filepath, contents, filetypes, bufferPosition}

fetchCompletions = ({editor, filepath, contents, filetypes, bufferPosition}) ->
  endpoint = if atom.config.get 'you-complete-me.legacyYcmdUse' then 'completions' else 'atom_completions'
  parameters = utility.buildRequestParameters filepath, contents, filetypes, bufferPosition
  handler.request('POST', endpoint, parameters).then (response) ->
    completions = response?.completions or []
    startColumn = (response?.completion_start_column or (bufferPosition.column + 1)) - 1
    prefix = editor.getTextInBufferRange [[bufferPosition.row, startColumn], bufferPosition]
    utility.handleException response
    return {completions, prefix, filetypes}

convertCompletions = ({completions, prefix, filetypes}) ->
  converters =
    general: (completion) ->
      suggestion = if atom.config.get 'you-complete-me.legacyYcmdUse'
        text: completion.insertion_text
        displayText: completion.menu_text
        replacementPrefix: prefix
        leftLabel: completion.extra_menu_info
        rightLabel: completion.kind
        description: ''
      else
        snippet: (
          placeholderIndex = 1
          completion.completion_chunks
            .map (chunk) -> if chunk.placeholder then "${#{placeholderIndex++}:#{chunk.chunk}}" else chunk.chunk
            .join ''
        )
        displayText: completion.display_string
        replacementPrefix: prefix
        leftLabel: completion.result_type
        rightLabel: completion.kind
        description: completion.doc_string
      suggestion.type = (
        switch completion.kind
          when '[File]', '[Dir]', '[File&Dir]' then 'import'
          else null
      )
      return suggestion

    clang: (completion) ->
      suggestion = converters.general completion
      suggestion.type = (
        switch completion.kind
          when 'TYPE', 'STRUCT', 'ENUM' then 'type'
          when 'CLASS' then 'class'
          when 'MEMBER' then 'property'
          when 'FUNCTION' then 'function'
          when 'VARIABLE', 'PARAMETER' then 'variable'
          when 'MACRO' then 'constant'
          when 'NAMESPACE' then 'keyword'
          when 'UNKNOWN' then 'value'
          else suggestion.type
      )
      return suggestion

    python: (completion) ->
      suggestion = converters.general completion
      suggestion.type = completion.display_string.substr(0, (completion.display_string.indexOf ': '))
      return suggestion

  formatter = (suggestion) ->
    if suggestion.leftLabel?.length > 20
      suggestion.leftLabel = "#{suggestion.leftLabel.substr 0, 20}…"
    return suggestion

  converter = converters[(
    switch filetypes[0]
      when 'c', 'cpp', 'objc', 'objcpp' then 'clang'
      when 'python' then 'python'
      else 'general'
  )]

  completions.map (completion) -> formatter converter completion

getSuggestions = (context) ->
  if context.prefix.startsWith ';' then return Promise.resolve []
  Promise.resolve context
    .then processContext
    .then fetchCompletions
    .then convertCompletions

module.exports = getSuggestions
