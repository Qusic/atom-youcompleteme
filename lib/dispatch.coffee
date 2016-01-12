{getEditorData, getEditorFiletype, buildRequestParameters} = require './utility'
handler = require './handler'
{CompositeDisposable} = require 'atom'


class Dispatcher
  constructor: (@handler, @fileStatusDb, @dispatchDispose=new CompositeDisposable()) ->

  buildFileReadyToParse = (handler, filedatas, bufferPosition = [0, 0]) ->
    parameters = buildRequestParameters filedatas, bufferPosition
    parameters.event_name = 'FileReadyToParse'
    handler.request('POST', 'event_notification', parameters)

  processReady: (context) ->
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

  dispose: ->
    @dispatchDispose.dispose()

buildBufferUnload = (filedata) ->
  parameters = buildRequestParameters [filedata]
  parameters.event_name = 'BufferUnload'
  parameters.unloaded_buffer = filedata.filepath
  handler.request('POST', 'event_notification', parameters).then ->
    @fileStatusDb.delFileEntry filedata.filepath

buildBufferVisit = (filedata) ->
  parameters = buildRequestParameters [filedata]
  parameters.event_name = 'BufferVisit'
  handler.request('POST', 'event_notification', parameters)

buildFileReadyToParse = (filedatas, bufferPosition = [0, 0]) ->
  parameters = buildRequestParameters filedatas, bufferPosition
  parameters.event_name = 'FileReadyToParse'
  handler.request('POST', 'event_notification', parameters)

processContext = ({editor, scopeDescriptor, bufferPosition}) ->
  getEditorData(editor, scopeDescriptor, bufferPosition).then ({filedatas, bufferPosition}) ->
    return {editor, filedatas, bufferPosition}

dispatchDispose = new CompositeDisposable()
dispose = ->
  dispatchDispose.dispose()

processVisit = (context) ->
  unless @fileStatusDb.getStatus context.editor.getPath(), 'visit'
    return buildBufferVisit(context.filedatas[0]).then ->
      @fileStatusDb.setStatus context.editor.getPath(), 'visit', true

      bak =
        filepath: context.editor.getPath()
        contents: ''
        filetypes: getEditorFiletype context.editor, context.editor.getRootScopeDescriptor()

      # add onDidDestroy
      destroy = ->
        unless @fileStatusDb.getStatus context.editor.getPath(), 'pending'
          buildBufferUnload bak
        else
          @fileStatusDb.setStatus context.editor.getPath(), 'closing', bak

      dispatchDispose.add context.editor.onDidDestroy destroy
      dispatchDispose.add context.editor.onDidChangePath destroy

      return context
  return context

processReady = (context) ->
  filepath = context.editor.getPath()
  @fileStatusDb.setStatus filepath, 'ready', true
  buildFileReadyToParse(context.filedatas, context.bufferPosition).then((response) ->
    @fileStatusDb.setStatus filepath, 'ready', false
    unless response?.exception?
      @fileStatusDb.setStatus filepath, 'firstready', true
    return response
  , (error) ->
    @fileStatusDb.setStatus filepath, 'ready', false
    throw error
  )

processFirstReady = (context) ->
  unless @fileStatusDb.getStatus context.editor.getPath(), 'firstready'
    return processReady(context).then -> context
  return context

processBefore = (needReady) ->
  choose = unless needReady
    (context) -> context
  else
    processFirstReady

  (context) ->
    @fileStatusDb.setStatus context.editor.getPath(), 'pending', true
    processContext context
      .then processVisit
      .then choose

_processAfter = (filepath) ->
  @fileStatusDb.setStatus filepath, 'pending', false
  if @fileStatusDb.getStatus filepath, 'closing'
    buildBufferUnload @fileStatusDb.getStatus filepath, 'closing'

processAfter = (filepath) ->
  (context) ->
    _processAfter filepath
    return context

processAfterError = (filepath) ->
  (error) ->
    _processAfter filepath
    throw error

module.exports =
  processReady: processReady
  processBefore: processBefore
  processAfter: processAfter
  processAfterError: processAfterError
  dispose: dispose
  Dispatcher: Dispatcher
