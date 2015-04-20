os = require 'os'
path = require 'path'
{File} = require 'atom'

module.exports =
  handler: require './ycm-handler'
  selector: '*'
  inclusionPriority: 1
  excludeLowerPriority: true

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
    @handler.request('POST', 'completions', parameters).then (response) ->
      completions = response.completions
      prefix = editor.getTextInBufferRange [[bufferPosition.row, response.completion_start_column - 1], bufferPosition]
      return {completions, prefix, filetypes}

  convertCompletions: ({completions, prefix, filetypes}) ->
    convertFunctions =
      general: (completion) ->
        text: completion.insertion_text
        replacementPrefix: prefix
        rightLabel: completion.extra_menu_info
        description: completion.detailed_info
      clang: (completion) ->
        text: completion.insertion_text
        replacementPrefix: prefix
        type: (
          switch completion.kind
            when 'TYPE', 'STRUCT', 'ENUM' then 'type'
            when 'CLASS' then 'class'
            when 'MEMBER' then 'property'
            when 'FUNCTION' then 'function'
            when 'VARIABLE', 'PARAMETER' then 'variable'
            when 'MACRO' then 'constant'
            when 'NAMESPACE' then 'keyword'
            when 'UNKNOWN' then 'value'
            else null
        )
        leftLabel: completion.extra_menu_info
        rightLabel: completion.kind
        description: completion.detailed_info
      python: (completion) ->
        text: completion.insertion_text
        replacementPrefix: prefix
        type: completion.extra_menu_info.substr(0, (completion.extra_menu_info.indexOf ': '))
        rightLabel: completion.extra_menu_info.substr((completion.extra_menu_info.indexOf ': ') + 2)
        description: completion.detailed_info
    completionType = switch filetypes[0]
      when 'c', 'cpp', 'objc', 'objcpp' then 'clang'
      when 'python' then 'python'
      else 'general'
    completions.map (completion) ->
      suggestion = convertFunctions[completionType](completion)
      if suggestion.leftLabel?.length > 20
        suggestion.leftLabel = "#{suggestion.leftLabel.substr 0, 20}…"
      if suggestion.leftLabel is '[File]' or suggestion.leftLabel is '[Dir]'
        suggestion.type ?= 'import'
      return suggestion

  getSuggestions: (context) ->
    Promise.resolve context
      .then @processContext.bind this
      .then @fetchCompletions.bind this
      .then @convertCompletions.bind this
      .catch (error) -> console.log '[YCM-ERROR]', error
