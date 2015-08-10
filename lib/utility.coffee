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
  handleException: handleException
