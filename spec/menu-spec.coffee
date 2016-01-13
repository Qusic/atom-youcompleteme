{Menu} = require '../lib/menu'
{singleEditorWith} = require './utility'

describe "Menu", ->
  class FileStatusDBFake


  beforeEach ->
    singleEditorWith fileExtension='c', content="int x = 42;", (editor) => @editor = editor

    runs ->
      dispatcher = jasmine.createSpyObj 'Dispatcher', ['processBefore', 'processAfter', 'processAfter']
      dispatcher.fileStatusDb = new FileStatusDBFake()
      spyOn(atom.notifications, 'addInfo')
      spyOn(atom.notifications, 'addError')
      spyOn(atom.commands, 'add')
      spyOn(atom.contextMenu, 'add').andReturn(jasmine.createSpyObj 'contextMenu', ['dispose'])
      spyOn(atom.workspace, 'open')

      @m = new Menu(dispatcher)

  it "should register new commands and fill the context menu", ->
    expect(@m.contextMenu).toBeUndefined()
    expect(@m.register()).toBe @m
    expect(@m.contextMenu).toBeDefined()

    numCommands = Object.keys(Menu.commands).length
    expect(atom.commands.add).toHaveBeenCalled()
    expect(Object.keys(atom.commands.add.mostRecentCall.args[1]).length).toBe numCommands

    expect(atom.contextMenu.add).toHaveBeenCalled()
    cm = atom.contextMenu.add.mostRecentCall.args[0]['atom-text-editor'][0]
    expect(cm.label).toEqual 'YouCompleteMe'
    expect(cm.submenu.length).toBe numCommands

  it "should dispose the context menu on deregister", ->
    expect(@m.register().deregister()).toBe @m
    expect(@m.contextMenu.dispose).toHaveBeenCalled()

  responses = [
    {message: 'hi from the serve'}
    {filepath: 'bogus.path'}
  ]

  for label, command of Menu.commands
    makeAssertions = (command, {mustOpenWorkspace, mustAddInfo}) -> ->
      asserter = (response) ->
        Menu.handler command: command, response: response
        expect(atom.workspace.open.callCount +
              atom.notifications.addInfo.callCount +
              atom.notifications.addError.callCount).toBeGreaterThan 0

      asserter response for response in responses

      expect(atom.notifications.addInfo).toHaveBeenCalled() if mustAddInfo
      expect(atom.workspace.open).toHaveBeenCalled() if mustOpenWorkspace

    if command.startsWith 'GoTo'
      customAssertionHandler = makeAssertions command, mustOpenWorkspace: true, mustAddInfo: false
      it "'#{command}' should try to open a workspace", customAssertionHandler
    else
      isGetter = command.startsWith 'Get'
      suffix = if isGetter then '' else ', at the very least'
      customAssertionHandler = makeAssertions command, mustOpenWorkspace: false, mustAddInfo: isGetter
      it "'#{command}' should show some sort of notification#{suffix}", customAssertionHandler

  return
