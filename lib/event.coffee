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
    onBufferVisit = -> emitEvent editor, 'BufferVisit'
    onBufferUnload = -> emitEvent editor, 'BufferUnload', unloaded_buffer: path
    onInsertLeave = -> emitEvent editor, 'InsertLeave'
    onCurrentIdentifierFinished = -> emitEvent editor, 'CurrentIdentifierFinished'

    observers = []
    observers.push editor.observeGrammar ->
      if isEnabled()
        onBufferVisit()
        enabled = true
      else
        onBufferUnload() if enabled
        enabled = false
    observers.push editor.onDidChangePath ->
      if enabled
        onBufferUnload()
        onBufferVisit()
      path = editor.getPath()
    observers.push editor.onDidStopChanging ->
      if enabled
        onInsertLeave()
        onCurrentIdentifierFinished()
    observers.push editor.onDidDestroy ->
      if enabled
        onBufferUnload()
      observer.dispose() for observer in observers

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
