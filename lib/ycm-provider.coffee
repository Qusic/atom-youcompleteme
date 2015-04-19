fs = require 'fs'
os = require 'os'
path = require 'path'

module.exports =
  handler: require './ycm-handler'
  selector: '*'
  inclusionPriority: 1
  excludeLowerPriority: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor}) ->
    Promise.resolve()
      .then () ->
        filepath = editor.buffer.file?.path
        if filepath?
          return filepath
        else
          return new Promise (fulfill, reject) ->
            filepath = path.resolve os.tmpdir(), "AtomYcmBuffer-#{editor.id}"
            fs.writeFile filepath, editor.buffer.cachedText, encoding: 'utf8', (error) ->
              unless error?
                fulfill filepath
              else
                reject error
      .then (filepath) ->
        parameters =
          line_num: bufferPosition.row + 1
          column_num: bufferPosition.column + 1
          filepath: filepath
          file_data: {}
        parameters.file_data[parameters.filepath] =
          filetypes: scopeDescriptor.scopes.map (scope) -> scope.split('.').pop()
          contents: editor.buffer.cachedText
        return parameters
      .then (parameters) =>
        @handler.request('POST', 'completions', parameters).then (response) ->
          prefix = editor.getTextInBufferRange [[bufferPosition.row, response.completion_start_column - 1], bufferPosition]
          response.completions.map (completion) ->
            text: completion.insertion_text
            replacementPrefix: prefix
            rightLabel: completion.extra_menu_info
      .catch (error) ->
        console.log '[YCM-ERROR]', error
