handler = require './handler'
utility = require './utility'
command = require './command'

processContext = (editor) ->
  utility.getEditorData(editor).then ({filepath, contents, filetypes}) ->
    return {filepath, contents, filetypes}

fetchIssues = ({filepath, contents, filetypes}) ->
  parameters = utility.buildRequestParameters filepath, contents, filetypes
  parameters.event_name = 'FileReadyToParse'
  handler.request('POST', 'event_notification', parameters).then (response) ->
    Promise.resolve if Array.isArray response then response else []
      .then (issues) -> Promise.all issues.map (issue) ->
        if issue.fixit_available
          command.run('FixIt', [issue.location.line_num - 1, issue.location.column_num - 1]).then (response) ->
            issue.fixits = if Array.isArray response?.fixits then response.fixits else []
            return issue
        else
          issue.fixits = []
          Promise.resolve issue
      .then (issues) -> {issues, filetypes}

convertIssues = ({issues, filetypes}) ->
  converter = (filetype) ->
    general = (issue) ->
      location:
        file: issue.location.filepath
        position: extractRangeFromIssue issue
      severity: 'error'
      excerpt: issue.text
      solutions: issue.fixits.map (solution) ->
        chunk = solution.chunks[0]
        position: extractRange(chunk.range)
        replaceWith: chunk.replacement_text

    clang = (issue) ->
      result = general issue
      result.severity = switch issue.kind
        when 'INFORMATION' then 'info'
        when 'WARNING' then 'warning'
        when 'ERROR' then 'error'
        else result.severity
      return result

    extractPoint = (point) -> [point.line_num - 1, point.column_num - 1]
    extractRange = (range) -> [extractPoint(range.start), extractPoint(range.end)]
    extractRangeFromIssue = ({location, location_extent}) ->
      if location_extent.start.line_num > 0 and location_extent.end.line_num > 0
        extractRange(location_extent)
      else
        [extractPoint(location), extractPoint(location)]

    switch filetype
      when 'c', 'cpp', 'objc', 'objcpp' then clang
      else general

  issues.map converter filetypes[0]

getIssues = (context) ->
  Promise.resolve context
    .then processContext
    .then fetchIssues
    .then convertIssues

module.exports = getIssues
