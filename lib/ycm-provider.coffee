module.exports =
  handler: require './ycm-handler'
  selector: '*'
  inclusionPriority: 1
  excludeLowerPriority: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor}) ->
    parameters =
      line_num: bufferPosition.row + 1
      column_num: bufferPosition.column + 1
      filepath: editor.buffer.file.path
      file_data: {}
    parameters.file_data[parameters.filepath] =
      filetypes: scopeDescriptor.scopes.map (scope) -> scope.split('.').pop()
      contents: editor.buffer.cachedText
    @handler.request('POST', 'completions', parameters).then (response) ->
      console.log '[YCM]', response
      prefix = editor.getTextInBufferRange [[bufferPosition.row, response.completion_start_column - 1], bufferPosition]
      response.completions.map (completion) ->
        text: completion.insertion_text
        replacementPrefix: prefix
        rightLabel: completion.extra_menu_info
      .catch (error) ->
        console.log '[YCM-ERROR]', error
