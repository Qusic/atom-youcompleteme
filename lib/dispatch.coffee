{getEditorData, getEditorFiletype, buildRequestParameters} = require './utility'
handler = require './handler'
{CompositeDisposable} = require 'atom'

processContext = ({editor, scopeDescriptor, bufferPosition}) ->
  getEditorData(editor, scopeDescriptor, bufferPosition).then ({filedatas, bufferPosition}) ->
    return {editor, filedatas, bufferPosition}

class Dispatcher
  constructor: (@handler, @fileStatusDb, @eventsDisposer=new CompositeDisposable()) ->

  buildFileReadyToParse = (handler, filedatas, bufferPosition = [0, 0]) ->
    parameters = buildRequestParameters filedatas, bufferPosition
    parameters.event_name = 'FileReadyToParse'
    handler.request('POST', 'event_notification', parameters)

  buildBufferUnload = (handler, fileStatusDb, filedata) ->
    parameters = buildRequestParameters [filedata]
    parameters.event_name = 'BufferUnload'
    parameters.unloaded_buffer = filedata.filepath
    handler.request('POST', 'event_notification', parameters).then ->
      fileStatusDb.delFileEntry filedata.filepath

  _processAfter = (filepath, handler, fileStatusDb) ->
    fileStatusDb.setStatus filepath, 'pending', false
    if fileStatusDb.getStatus filepath, 'closing'
      buildBufferUnload handler, fileStatusDb, fileStatusDb.getStatus(filepath, 'closing')

  processReady: (context) =>
    filepath = context.editor.getPath()
    @fileStatusDb.setStatus filepath, 'ready', true
    buildFileReadyToParse(@handler, context.filedatas, context.bufferPosition).then((response) =>
      @fileStatusDb.setStatus filepath, 'ready', false
      unless response?.exception?
        @fileStatusDb.setStatus filepath, 'firstready', true
      return response
    , (error) =>
      @fileStatusDb.setStatus filepath, 'ready', false
      throw error
    )

  processBefore: (needProcessFirstReady) =>
    handleContext = unless needProcessFirstReady
      (context) -> context
    else
      (context) =>
        unless @fileStatusDb.getStatus context.editor.getPath(), 'firstready'
          @processReady(context).then -> context
        else context

    buildBufferVisit = (handler, filedata) ->
      parameters = buildRequestParameters [filedata]
      parameters.event_name = 'BufferVisit'
      handler.request('POST', 'event_notification', parameters)

    processVisit = (context) =>
      return context if @fileStatusDb.getStatus context.editor.getPath(), 'visit'

      buildBufferVisit(@handler, context.filedatas[0]).then =>
        @fileStatusDb.setStatus context.editor.getPath(), 'visit', true

        bak =
          filepath: context.editor.getPath()
          contents: ''
          filetypes: getEditorFiletype context.editor, context.editor.getRootScopeDescriptor()

        # add onDidDestroy
        destroy = =>
          unless @fileStatusDb.getStatus context.editor.getPath(), 'pending'
            buildBufferUnload @handler, @fileStatusDb, bak
          else
            @fileStatusDb.setStatus context.editor.getPath(), 'closing', bak

        for fn in ['onDidDestroy', 'onDidChangePath']
          eventsDisposer.add context.editor[fn] destroy

        return context

    (context) =>
      @fileStatusDb.setStatus context.editor.getPath(), 'pending', true
      processContext context
        .then processVisit
        .then handleContext

  processAfter: (filepath) =>
    (context) ->
      _processAfter filepath, @handler, @fileStatusDb
      return context

  processAfterError: (filepath) =>
    (error) ->
      _processAfter filepath, @handler, @fileStatusDb
      throw error

  dispose: ->
    @eventsDisposer.dispose()

  runCommand: (command, responseHandler) =>
    editor = atom.workspace.getActiveTextEditor()
    return Promise.resolve() unless editor.getPath()?
    return Promise.resolve() if @fileStatusDb.getStatus editor.getPath(), 'ready'
    return Promise.resolve() if @fileStatusDb.getStatus editor.getPath(), 'closing'

    filepath = editor.getPath()
    Promise.resolve {editor}
      .then @processBefore(true)
      .then ({filedatas, bufferPosition}) =>
        parameters = buildRequestParameters filedatas, bufferPosition
        parameters.command_arguments = [command]
        @handler.request('POST', 'run_completer_command', parameters).then (response) ->
          responseHandler response: response, command: command
      .then @processAfter(filepath), @processAfterError(filepath)

module.exports =
  Dispatcher: Dispatcher
