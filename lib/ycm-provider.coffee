os = require 'os'
path = require 'path'
{File} = require 'atom'

module.exports =
  handler: require './ycm-handler'
  selector: '.source.c, .source.cpp, .source.objc, .source.objcpp, .source.python'
  inclusionPriority: 1
  excludeLowerPriority: false

  processContext: ({editor, bufferPosition, scopeDescriptor}) ->
    filepath = editor.getPath()
    contents = editor.getText()
    filetypes = scopeDescriptor.getScopesArray().map (scope) -> scope.split('.').pop()
    if filepath?
      return {filepath, contents, filetypes, editor, bufferPosition}
    else
      return new Promise (fulfill, reject) ->
        filepath = path.resolve os.tmpdir(), "AtomYcmBuffer-#{editor.id}"
        file = new File filepath
        file.write(contents)
          .then () -> fulfill {filepath, contents, filetypes, editor, bufferPosition}
          .catch (error) -> reject error

  fetchCompletions: ({filepath, contents, filetypes, editor, bufferPosition}) ->
    parameters =
      line_num: bufferPosition.row + 1
      column_num: bufferPosition.column + 1
      filepath: filepath
      file_data: {}
    parameters.file_data[filepath] =
      contents: contents
      filetypes: filetypes
    @handler.request('POST', 'atom_completions', parameters).then (response) ->
      completions = response?.completions or []
      startColumn = (response?.completion_start_column or (bufferPosition.column + 1)) - 1
      prefix = editor.getTextInBufferRange [[bufferPosition.row, startColumn], bufferPosition]
      return {completions, prefix, filetypes}

  convertCompletions: ({completions, prefix, filetypes}) ->
    converters =
      general: (completion) ->
        snippet: (
          placeholderIndex = 1
          completion.completion_parts
            .map (part) -> if part.literal then part.part else "${#{placeholderIndex++}:#{part.part}}"
            .join ''
        )
        displayText: completion.display_string
        replacementPrefix: prefix
        leftLabel: completion.result_type
        rightLabel: completion.kind
        description: completion.doc_string
        type: (
          switch completion.kind
            when '[File]', '[Dir]', '[File&Dir]' then 'import'
            else null
        )

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

  getSuggestions: (context) ->
    Promise.resolve context
      .then @processContext.bind this
      .then @fetchCompletions.bind this
      .then @convertCompletions.bind this
      .catch (error) -> console.error '[YCM-ERROR]', error
