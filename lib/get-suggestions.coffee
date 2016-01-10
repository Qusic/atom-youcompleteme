handler = require './handler'
utility = require './utility'
dispatch = require './dispatch'
lexer = require './lexer'
path = require 'path'

fetchCompletions = (handler, activatedManually) -> ({editor, filedatas, bufferPosition}) ->
  parameters = utility.buildRequestParameters filedatas, bufferPosition
  if activatedManually or atom.config.get 'you-complete-me.forceComplete'
    parameters.force_semantic = true
  parameters.working_dir = path.dirname parameters.filepath
  handler.request('POST', 'completions', parameters).then (response) ->
    completions = response?.completions or []
    startColumn = (response?.completion_start_column or (bufferPosition.column + 1)) - 1
    prefix = editor.getTextInBufferRange [[bufferPosition.row, startColumn], bufferPosition]
    return {completions, prefix, filetypes: filedatas[0].filetypes}

convertCompletions = (lexer, {completions, prefix, filetypes}) ->
  converters =
    general: (completion) ->
      suggestion =
        text: completion.insertion_text
        displayText: completion.menu_text
        replacementPrefix: prefix
        leftLabel: completion.extra_menu_info
        rightLabel: completion.kind
        description: ''
      suggestion.type = (
        switch completion.kind
          when '[File]', '[Dir]', '[File&Dir]' then 'import'
          else null
      )
      return suggestion

    clang: (completion) ->
      return lexer.clangFunctionLexer completion, prefix if completion.kind is 'FUNCTION'
      suggestion = converters.general completion
      suggestion.type = (
        switch completion.kind
          when 'TYPE', 'STRUCT', 'ENUM' then 'type'
          when 'CLASS' then 'class'
          when 'MEMBER' then 'property'
          when 'FUNCTION' then 'function'
          when 'VARIABLE', 'PARAMETER' then 'variable'
          when 'MACRO' then 'constant'
          when 'NAMESPACE' then 'package'
          when 'UNKNOWN' then 'value'
          else suggestion.type
      )
      return lexer.clangGeneralPlus completion, suggestion

    python: (completion) ->
      suggestion = converters.general completion
      suggestion.type = completion.display_string.substr(0, (completion.display_string.indexOf ': '))
      return suggestion

    rust: (completion) ->
      suggestion = converters.general completion
      # suggestion.snippet = suggestion.text
      suggestion.description = suggestion.leftLabel
      delete suggestion.text
      suggestion

  converter = converters[(
    switch filetypes[0]
      when 'c', 'cpp', 'objc', 'objcpp' then 'clang'
      when 'python' then 'python'
      when 'rust' then 'rust'
      else 'general'
  )]

  r = completions.map (completion) -> converter completion
  if r.length > 0 and Array.isArray(r[0]) then r = r.reduce (prev, cur) -> prev.concat cur
  return r

getSuggestions = (context, dispatch, handler, lexer) ->
  return Promise.resolve [] unless context.editor.getPath()?
  return Promise.resolve [] if utility.setFileStatus context.editor.getPath(), 'ready'
  return Promise.resolve [] if utility.getFileStatus context.editor.getPath(), 'closing'

  filepath = context.editor.getPath()
  Promise.resolve context
    .then dispatch.processBefore(true)
    .then fetchCompletions(handler, context.activatedManually)
    .then dispatch.processAfter(filepath), dispatch.processAfterError(filepath)
    .then convertCompletions lexer

suggestionsInjector = (dispatch, handler, lexer) ->
  (context) ->
    getSuggestions(context, dispatch, handler, lexer)

module.exports =
  getSuggestions: suggestionsInjector(dispatch, handler, lexer)
  injector: suggestionsInjector
