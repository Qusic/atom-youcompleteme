handler = require './handler'
utility = require './utility'

completerCommands = {}
contextMenu = null

getCommands = ->
  filetype = utility.getEditorFiletype()
  if completerCommands.hasOwnProperty filetype
    return completerCommands[filetype]
  else
    Promise.resolve()
      .then utility.getEditorData
      .then ({filepath, contents, filetypes}) ->
        parameters = utility.buildRequestParameters filepath, contents, filetypes
        parameters.completer_target = filetype
        handler.request('POST', 'defined_subcommands', parameters).then (response) ->
          completerCommands[filetype] = if Array.isArray response then response else []
    return ['Querying...']

runCommand = (command) ->
  Promise.resolve()
    .then utility.getEditorData
    .then ({filepath, contents, filetypes, bufferPosition}) ->
      parameters = utility.buildRequestParameters filepath, contents, filetypes, bufferPosition
      handler.request('POST', 'run_completer_command', parameters).then (response) ->

register = ->
  atom.commands.add 'atom-text-editor', 'you-complete-me:command', (event) ->
    # TODO: No API to know which command is invoked here.
  contextMenu = atom.contextMenu.add
    'atom-text-editor': [{
      label: 'YouCompleteMe'
      created: (event) -> @submenu = getCommands().map (command) ->
        label: command
        command: 'you-complete-me:command'
    }]

deregister = ->
  contextMenu?.dispose()

module.exports =
  register: register
  deregister: deregister
