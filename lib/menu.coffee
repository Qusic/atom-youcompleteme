handler = require './handler'
utility = require './utility'

commands =
  'get-type': 'GetType'
  'get-parent': 'GetParent'
  'go-to-declaration': 'GoToDeclaration'
  'go-to-definition': 'GoToDefinition'
  'go-to': 'GoTo'
  'go-to-imprecise': 'GoToImprecise'
  #'fix-it': 'FixIt' # TODO
  'clear-compilation-flag-cache': 'ClearCompilationFlagCache'
contextMenu = null

runCommand = (command) ->
  Promise.resolve()
    .then utility.getEditorData
    .then ({filepath, contents, filetypes, bufferPosition}) ->
      parameters = utility.buildRequestParameters filepath, contents, filetypes, bufferPosition
      parameters.command_arguments = [command]
      handler.request('POST', 'run_completer_command', parameters).then (response) ->
        if command.startsWith 'Get'
          if response?.message?
            atom.notifications.addInfo "[YCM] #{command}", detail: response.message
        else if command.startsWith 'GoTo'
          if response?.filepath?
            atom.workspace.open response.filepath, initialLine: response.line_num - 1, initialColumn: response.column_num - 1

register = ->
  generatedCommands = {}
  generatedMenus = []
  Object.keys(commands).forEach (key) ->
    command = commands[key]
    generatedCommands["you-complete-me:#{key}"] = (event) -> runCommand(command).catch utility.notifyError()
    generatedMenus.push command: "you-complete-me:#{key}", label: command
  atom.commands.add 'atom-text-editor', generatedCommands
  contextMenu = atom.contextMenu.add 'atom-text-editor': [label: 'YouCompleteMe', submenu: generatedMenus]

deregister = ->
  contextMenu.dispose()

module.exports =
  register: register
  deregister: deregister
  runCommand: runCommand
