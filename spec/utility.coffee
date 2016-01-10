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

module.exports =
  assurePluginLoadedWithLanguage: assurePluginLoadedWithLanguage
  assurePluginLoaded: -> assurePluginLoadedWithLanguage(undefined)
  openWorkspaceWithEditor: openWorkspaceWithEditor
  singleEditorWith: singleEditorWith
