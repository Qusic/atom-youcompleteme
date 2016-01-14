getCompileEvents = (context, dispatcher) ->
  fetchEvents = (context) ->
    dispatcher.processReady(context).then (response) ->
      events = if Array.isArray response then response else []
      return {events}

  convertEvents = ({events}) ->
    extractRange = (event) ->
      if event.location_extent.start.line_num > 0 and event.location_extent.end.line_num > 0 then [
        [event.location_extent.start.line_num - 1, event.location_extent.start.column_num - 1]
        [event.location_extent.end.line_num - 1, event.location_extent.end.column_num - 1]
      ] else [
        [event.location.line_num - 1, event.location.column_num - 1]
        [event.location.line_num - 1, event.location.column_num - 1]
      ]

    events.map (event) ->
      type: event.kind
      text: event.text
      filePath: event.location.filepath
      range: extractRange event

  return Promise.resolve [] unless context.getPath()?
  return Promise.resolve [] if dispatcher.fileStatusDb.getStatus context.getPath(), 'ready'
  return Promise.resolve [] if dispatcher.fileStatusDb.getStatus context.getPath(), 'closing'

  filepath = context.getPath()
  Promise.resolve {editor: context}
    .then dispatcher.processBefore(false)
    .then fetchEvents
    .then dispatcher.processAfter(filepath), dispatcher.processAfterError(filepath)
    .then convertEvents


module.exports =
  getCompileEvents: getCompileEvents
