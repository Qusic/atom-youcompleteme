handler = require './handler'
utility = require './utility'

processContext = (editor) ->
  utility.getEditorData(editor).then ({filepath, contents}) ->
    return {filepath, contents}

fetchEvents = ({filepath, contents}) ->
  parameters = utility.buildRequestParameters filepath, contents, ['cpp']
  parameters.event_name = 'FileReadyToParse'
  handler.request('POST', 'event_notification', parameters).then (response) ->
    events = if Array.isArray response then response else []
    utility.handleException response
    return {events, filepath}

convertEvents = ({events, filepath}) ->
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
    filePath: filepath
    range: extractRange event

getCompileEvents = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchEvents
    .then convertEvents

module.exports = getCompileEvents
