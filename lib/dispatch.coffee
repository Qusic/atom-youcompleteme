utility = require './utility'
handler = require './handler'
{CompositeDisposable} = require 'atom'

buildBufferUnload = (filedata) ->
  parameters = utility.buildRequestParameters [filedata]
  parameters.event_name = 'BufferUnload'
  parameters.unloaded_buffer = filedata.filepath
  handler.request('POST', 'event_notification', parameters).then ->
    utility.delFileStatus filedata.filepath

buildBufferVisit = (filedata) ->
  parameters = utility.buildRequestParameters [filedata]
  parameters.event_name = 'BufferVisit'
  handler.request('POST', 'event_notification', parameters)

buildFileReadyToParse = (filedatas, bufferPosition = [0, 0]) ->
  parameters = utility.buildRequestParameters filedatas, bufferPosition
  parameters.event_name = 'FileReadyToParse'
  handler.request('POST', 'event_notification', parameters)

processContext = ({editor, scopeDescriptor, bufferPosition}) ->
  utility.getEditorData(editor, scopeDescriptor, bufferPosition).then ({filedatas, bufferPosition}) ->
    return {editor, filedatas, bufferPosition}

dispatchDispose = new CompositeDisposable()
dispose = ->
  dispatchDispose.dispose()

processVisit = (context) ->
  unless utility.getFileStatus context.editor.getPath(), 'visit'
    return buildBufferVisit(context.filedatas[0]).then ->
      utility.setFileStatus context.editor.getPath(), 'visit', true

      bak =
        filepath: context.editor.getPath()
        contents: ''
        filetypes: utility.getEditorFiletype context.editor, context.editor.getRootScopeDescriptor()

      # add onDidDestroy
      destroy = ->
        unless utility.getFileStatus context.editor.getPath(), 'pending'
          buildBufferUnload bak
        else
          utility.setFileStatus context.editor.getPath(), 'closing', bak

      dispatchDispose.add context.editor.onDidDestroy destroy
      dispatchDispose.add context.editor.onDidChangePath destroy

      return context
  return context

processReady = (context) ->
  filepath = context.editor.getPath()
  utility.setFileStatus filepath, 'ready', true
  buildFileReadyToParse(context.filedatas, context.bufferPosition).then((response) ->
    utility.setFileStatus filepath, 'ready', false
    unless response?.exception?
      utility.setFileStatus filepath, 'firstready', true
    return response
  , (error) ->
    utility.setFileStatus filepath, 'ready', false
    throw error
  )

processFirstReady = (context) ->
  unless utility.getFileStatus context.editor.getPath(), 'firstready'
    return processReady(context).then -> context
  return context

processBefore = (needReady) ->
  choose = unless needReady
    (context) -> context
  else
    processFirstReady

  (context) ->
    utility.setFileStatus context.editor.getPath(), 'pending', true
    processContext context
      .then processVisit
      .then choose

_processAfter = (filepath) ->
  utility.setFileStatus filepath, 'pending', false
  if utility.getFileStatus filepath, 'closing'
    buildBufferUnload utility.getFileStatus filepath, 'closing'

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
