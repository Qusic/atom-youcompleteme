os = require 'os'
path = require 'path'
{File} = require 'atom'

getEditorData = (editor = atom.workspace.getActiveTextEditor(), scopeDescriptor = editor.getRootScopeDescriptor()) ->
  filepath = editor.getPath()
  contents = editor.getText()
  filetypes = scopeDescriptor.getScopesArray().map (scope) -> scope.split('.').pop()
  bufferPosition = editor.getCursorBufferPosition()
  if filepath?
    return Promise.resolve {filepath, contents, filetypes, bufferPosition}
  else
    return new Promise (fulfill, reject) ->
      filepath = path.resolve os.tmpdir(), "AtomYcmBuffer-#{editor.id}"
      file = new File filepath
      file.write contents
        .then -> fulfill {filepath, contents, filetypes, bufferPosition}
        .catch (error) -> reject error

getEditorFiletype = (scopeDescriptor = atom.workspace.getActiveTextEditor().getRootScopeDescriptor()) ->
  return scopeDescriptor.getScopesArray()[0].split('.').pop()

buildRequestParameters = (filepath, contents, filetypes = [], bufferPosition = [0, 0]) ->
  parameters =
    filepath: filepath
    line_num: bufferPosition.row + 1
    column_num: bufferPosition.column + 1
    file_data: {}
  parameters.file_data[filepath] =
    contents: contents
    filetypes: filetypes
  return parameters

handleException = (response) ->
  notifyException = ->
    atom.notifications.addError "[YCM] #{response.exception.TYPE} #{response.message}", detail: "#{response.traceback}"

  confirmExtraConfig = ->
    filepath = response.exception.extra_conf_file
    message = response.message
    atom.confirm
      message: '[YCM] Unknown Extra Config'
      detailedMessage: message
      buttons:
        Load: -> handler.request 'POST', 'load_extra_conf_file', {filepath}
        Ignore: -> handler.request 'POST', 'ignore_extra_conf_file', {filepath}

  if response?.exception?
    switch response.exception.TYPE
      when 'UnknownExtraConf' then confirmExtraConfig()
      else notifyException()

module.exports =
  getEditorData: getEditorData
  getEditorFiletype: getEditorFiletype
  buildRequestParameters: buildRequestParameters
  handleException: handleException
