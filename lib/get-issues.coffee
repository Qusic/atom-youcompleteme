handler = require './handler'
utility = require './utility'

processContext = (editor) ->
  utility.getEditorData(editor).then ({filepath, contents, filetypes}) ->
    return {filepath, contents, filetypes}

fetchIssues = ({filepath, contents, filetypes}) ->
  parameters = utility.buildRequestParameters filepath, contents, filetypes
  parameters.event_name = 'FileReadyToParse'
  handler.request('POST', 'event_notification', parameters).then (response) ->
    issues = if Array.isArray response then response else []
    return {issues}

convertIssues = ({issues}) ->
  extractRange = (issue) ->
    if issue.location_extent.start.line_num > 0 and issue.location_extent.end.line_num > 0 then [
      [issue.location_extent.start.line_num - 1, issue.location_extent.start.column_num - 1]
      [issue.location_extent.end.line_num - 1, issue.location_extent.end.column_num - 1]
    ] else [
      [issue.location.line_num - 1, issue.location.column_num - 1]
      [issue.location.line_num - 1, issue.location.column_num - 1]
    ]

  issues.map (issue) ->
    type: issue.kind
    text: issue.text
    filePath: issue.location.filepath
    range: extractRange issue

getIssues = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchIssues
    .then convertIssues

module.exports = getIssues
