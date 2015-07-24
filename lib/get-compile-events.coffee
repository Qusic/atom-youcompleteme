os = require 'os'
path = require 'path'
{File} = require 'atom'

handler = require './handler'

extractRange = (e) ->
  if e.location_extent.start.line_num > 0 and e.location_extent.end.line_num > 0
    [
      [e.location_extent.start.line_num - 1, e.location_extent.start.column_num - 1]
      [e.location_extent.end.line_num - 1, e.location_extent.end.column_num - 1]
    ]
  else
    [
      [e.location.line_num - 1, e.location.column_num - 1]
      [e.location.line_num - 1, e.location.column_num - 1]
    ]

processContext = (context) ->
  editor = context
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
  handler.request('POST', 'event_notification', parameters)
    .catch (error) ->
      console.log error
    .then (response) ->
      return [] unless Array.isArray response
      issues = response.map (e) ->
        type: e.kind
        text: e.text
        filePath: filepath
        range: extractRange(e)
      return issues

getCompileEvents = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchEvents

module.exports = getCompileEvents
