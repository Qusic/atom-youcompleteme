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
    path = null
    isEnabled = -> utility.isEnabledForScope editor.getRootScopeDescriptor()
    onBufferVisit = ->
      path = editor.getPath() or utility.getEditorTmpFilepath editor
      emitEvent editor, 'BufferVisit'
    onBufferUnload = ->
      emitEvent editor, 'BufferUnload', unloaded_buffer: path
      path = null
    onFileReadyToParse = -> emitEvent editor, 'FileReadyToParse'
    onCurrentIdentifierFinished = -> emitEvent editor, 'CurrentIdentifierFinished'

    observers = new CompositeDisposable()
    observers.add editor.observeGrammar ->
      if isEnabled()
        onBufferVisit()
        onFileReadyToParse()
      else if path?
        onBufferUnload()
    observers.add editor.onDidChangePath ->
      if path?
        onBufferUnload()
      if isEnabled()
        onBufferVisit()
        onFileReadyToParse()
    observers.add editor.onDidStopChanging ->
      if path?
        onCurrentIdentifierFinished()
        onFileReadyToParse()
    observers.add editor.onDidDestroy ->
      if path?
        onBufferUnload()
      observers.dispose()

observeConfig = ->
  atom.config.observe 'you-complete-me', (value) ->
    handler.reset()

register = ->
  disposables = new CompositeDisposable()
  disposables.add observeEditors()
  disposables.add observeConfig()

deregister = ->
  disposables.dispose()

module.exports =
  register: register
  deregister: deregister
