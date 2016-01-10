assurePluginLoadedWithLanguage = (language) ->
  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('you-complete-me')
    language and waitsForPromise -> atom.packages.activatePackage('language-' + language)

openWorkspaceWithEditor = (fileExtension, setEditor) ->
  beforeEach ->
    waitsForPromise -> atom.workspace.open('test.' + fileExtension)
    runs -> setEditor atom.workspace.getActiveTextEditor()

waitsForResolve = (promise) ->
  waitsForPromise ->
    promise
      .catch (err) ->
        expect('promise').toBe('successful, got ' + err)


module.exports =
  assurePluginLoadedWithLanguage: assurePluginLoadedWithLanguage
  assurePluginLoaded: -> assurePluginLoadedWithLanguage(undefined)
  openWorkspaceWithEditor: openWorkspaceWithEditor
  waitsForResolve: waitsForResolve
