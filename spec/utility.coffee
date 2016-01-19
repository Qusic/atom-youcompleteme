{FileStatusDB} = require '../lib/utility'

assurePluginLoadedWithLanguage = (language) ->
  waitsForPromise -> atom.packages.activatePackage('you-complete-me')
  language and waitsForPromise -> atom.packages.activatePackage('language-' + language)

openWorkspaceWithEditor = (fileExtension, setEditor) ->
  waitsForPromise -> atom.workspace.open('test.' + fileExtension)
  runs -> setEditor atom.workspace.getActiveTextEditor()

singleEditorWith = (fileExtension, content, setEditor) ->
  assurePluginLoadedWithLanguage fileExtension
  openWorkspaceWithEditor fileExtension='c', (openedEditor) ->
    openedEditor.setText content
    setEditor? openedEditor

dispatcherMock = ->
  dispatcher = jasmine.createSpyObj('dispatcher', ['processBefore', 'processAfter', 'processAfterError'])
  dispatcher.processBefore.andReturn (context) -> context
  dispatcher.processAfter.andReturn (context) -> context
  dispatcher.processAfterError.andCallFake (filePath) -> (error) -> throw error
  dispatcher.fileStatusDb = new FileStatusDB()
  dispatcher.handler = jasmine.createSpyObj('handler', ['request'])
  dispatcher.handler.request.andCallFake -> Promise.resolve()
  dispatcher


module.exports =
  assurePluginLoadedWithLanguage: assurePluginLoadedWithLanguage
  assurePluginLoaded: -> assurePluginLoadedWithLanguage(undefined)
  openWorkspaceWithEditor: openWorkspaceWithEditor
  singleEditorWith: singleEditorWith
  dispatcherMock: dispatcherMock
