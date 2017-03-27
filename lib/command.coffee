handler = require './handler'
utility = require './utility'

commands =
  'get-type': 'GetType'
  'get-parent': 'GetParent'
  'go-to-declaration': 'GoToDeclaration'
  'go-to-definition': 'GoToDefinition'
  'go-to': 'GoTo'
  'go-to-imprecise': 'GoToImprecise'
  'clear-compilation-flag-cache': 'ClearCompilationFlagCache'
contextMenu = null

run = (command, position, action) ->
  Promise.resolve()
    .then utility.getEditorData
    .then ({filepath, contents, filetypes, bufferPosition}) ->
      parameters = utility.buildRequestParameters filepath, contents, filetypes, position or bufferPosition
      parameters.command_arguments = [command]
      handler.request('POST', 'run_completer_command', parameters).then (response) ->
        if action
          if command.startsWith('Get') and response?.message?
            atom.notifications.addInfo "[YCM] #{command}", detail: response.message
          else if command.startsWith('GoTo') and response?.filepath?
            atom.workspace.open response.filepath, initialLine: response.line_num - 1, initialColumn: response.column_num - 1
        return response

register = ->
  generatedCommands = {}
  generatedMenus = []
  Object.keys(commands).forEach (key) ->
    command = commands[key]
    generatedCommands["you-complete-me:#{key}"] = (event) -> run(command, null, true).catch utility.notifyError()
    generatedMenus.push command: "you-complete-me:#{key}", label: command
  atom.commands.add 'atom-text-editor', generatedCommands
  contextMenu = atom.contextMenu.add 'atom-text-editor': [label: 'YouCompleteMe', submenu: generatedMenus]

deregister = ->
  contextMenu.dispose()

module.exports = {
  register
  deregister
  run
}
