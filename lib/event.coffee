handler = require './handler'
utility = require './utility'

editorsObserver = null
configObserver = null

emitEvent = (editor, name, args) ->
  utility.getEditorData(editor).then ({filepath, contents, filetypes}) ->
    parameters = utility.buildRequestParameters filepath, contents, filetypes
    parameters.event_name = name
    parameters[key] = value for key, value of args
    handler.request('POST', 'event_notification', parameters)

observeEditors = ->
  atom.workspace.observeTextEditors (editor) ->
    path = editor.getPath() or utility.getEditorTmpFilepath editor
    enabled = false
    isEnabled = -> utility.isEnabledForScope editor.getRootScopeDescriptor()
    onVisit = -> emitEvent editor, 'BufferVisit'
    onUnload = -> emitEvent editor, 'BufferUnload', unloaded_buffer: path

    grammarObserver = editor.observeGrammar ->
      if isEnabled()
        onVisit()
        enabled = true
      else
        onUnload() if enabled
        enabled = false
    pathObserver = editor.onDidChangePath ->
      if enabled
        onUnload()
        onVisit()
      path = editor.getPath()
    destroyObserver = editor.onDidDestroy ->
      if enabled
        onUnload()
      grammarObserver.dispose()
      pathObserver.dispose()
      destroyObserver.dispose()

observeConfig = ->
  atom.config.observe 'you-complete-me', (value) ->
    handler.reset()

register = ->
  editorsObserver = observeEditors()
  configObserver = observeConfig()

deregister = ->
  editorsObserver.dispose()
  configObserver.dispose()

module.exports =
  register: register
  deregister: deregister
