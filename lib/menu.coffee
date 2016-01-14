{buildRequestParameters} = require './utility'
dispatch = require './dispatch'

class Menu
  constructor: (@dispatch, @commands=Menu.commands) ->
  register: =>
    generatedCommands = {}
    generatedMenus = []

    for key, command of @commands
      generatedCommands["you-complete-me:#{key}"] = ((command) => (event) => @dispatch.runCommand command, Menu.handler)(command)
      generatedMenus.push command: "you-complete-me:#{key}", label: command
    atom.commands.add 'atom-text-editor', generatedCommands
    @contextMenu = atom.contextMenu.add 'atom-text-editor': [label: 'YouCompleteMe', submenu: generatedMenus]
    this

  deregister: =>
    @contextMenu?.dispose()
    this

Menu.commands =
  'get-type': 'GetType'
  'get-parent': 'GetParent'
  'go-to-declaration': 'GoToDeclaration'
  'go-to-definition': 'GoToDefinition'
  'go-to': 'GoTo'
  'go-to-imprecise': 'GoToImprecise'
  'go-to-include': 'GoToInclude'
  #'fix-it': 'FixIt' # TODO
  'clear-compilation-flag-cache': 'ClearCompilationFlagCache'

Menu.handler = ({response, command}) ->
  fmt = -> "[YCM] #{command}"
  noResult = -> atom.notifications.addInfo fmt(), detail: 'no result'

  if command.startsWith 'Get'
    if response?.message?
      atom.notifications.addInfo fmt(), detail: response.message
    else noResult()
  else if command.startsWith 'GoTo'
    if response?.filepath?
      atom.workspace.open response.filepath, initialLine: response.line_num - 1, initialColumn: response.column_num - 1
    else noResult()
  else
    atom.notifications.addError fmt()

module.exports =
  Menu: Menu
