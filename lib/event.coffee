{CompositeDisposable} = require 'atom'

handler = require './handler'
utility = require './utility'

disposables = null

emitEvent = (editor, name, args) ->
  utility.getEditorData(editor).then ({filepath, contents, filetypes}) ->
    parameters = utility.buildRequestParameters filepath, contents, filetypes
    parameters.event_name = name
    parameters[key] = value for key, value of args
    handler.request('POST', 'event_notification', parameters).catch utility.notifyError()

observeEditors = ->
  atom.workspace.observeTextEditors (editor) ->
    path = editor.getPath() or utility.getEditorTmpFilepath editor
    enabled = false
    isEnabled = -> utility.isEnabledForScope editor.getRootScopeDescriptor()
    onBufferVisit = -> emitEvent editor, 'BufferVisit'
    onBufferUnload = -> emitEvent editor, 'BufferUnload', unloaded_buffer: path
    onInsertLeave = -> emitEvent editor, 'InsertLeave'
    onCurrentIdentifierFinished = -> emitEvent editor, 'CurrentIdentifierFinished'
    onFileReadyToParse = -> emitEvent editor, 'FileReadyToParse'

    observers = new CompositeDisposable()
    observers.add editor.observeGrammar ->
      if isEnabled()
        onBufferVisit()
        onFileReadyToParse()
        enabled = true
      else
        onBufferUnload() if enabled
        enabled = false
    observers.add editor.onDidChangePath ->
      if enabled
        onBufferUnload()
        onBufferVisit()
        onFileReadyToParse()
      path = editor.getPath()
    observers.add editor.onDidStopChanging ->
      if enabled
        onInsertLeave()
        onCurrentIdentifierFinished()
        onFileReadyToParse()
    observers.add editor.onDidDestroy ->
      if enabled
        onBufferUnload()
      observers.dispose()

observeConfig = ->
  atom.config.observe 'TabNine', (value) ->
    handler.reset()

register = ->
  disposables = new CompositeDisposable()
  disposables.add observeEditors()
  disposables.add observeConfig()

deregister = ->
  disposables.dispose()

module.exports = {
  register
  deregister
}
