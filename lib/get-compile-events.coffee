handler = require './handler'

processContext = (editor) ->
  filepath = editor.getPath()
  contents = editor.getText()
  return {filepath, contents}

fetchEvents = ({filepath, contents}) ->
  parameters =
    event_name: 'FileReadyToParse'
    filepath: filepath
    file_data: {}
    line_num: 1
    column_num: 1
  parameters.file_data[filepath] =
    contents: contents
    filetypes: ['cpp']
  handler.request('POST', 'event_notification', parameters).then (response) ->
    events = if Array.isArray response then response else []
    if response?.exception?
      switch response.exception.TYPE
        when 'UnknownExtraConf'
          filepath = response.exception.extra_conf_file
          atom.confirm
            message: '[YCM] Unknown Extra Config'
            detailedMessage: response.message
            buttons:
              Load: -> handler.request 'POST', 'load_extra_conf_file', {filepath}
              Ignore: -> handler.request 'POST', 'ignore_extra_conf_file', {filepath}
        else
          atom.notifications.addError "[YCM] #{response.exception.TYPE} #{response.message}", detail: "#{response.traceback}"
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
