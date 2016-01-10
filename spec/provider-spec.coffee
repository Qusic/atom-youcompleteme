{injector} = require '../lib/get-suggestions'
{assurePluginLoadedWithLanguage, openWorkspaceWithEditor} = require './utility'

describe "YCMD autocompletions", ->
  [editor, provider, getYcmdSuggestions] = []

  assertSuccessfulCompletions = (assertionCallback, providerInstance = provider) ->
    waitsForPromise -> getCompletions(providerInstance).then assertionCallback

  getCompletions = (provider) ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEachFor = (languageToLoad, withFileExtension, withDefaultProvider = true) ->
    beforeEach ->
      assurePluginLoadedWithLanguage(languageToLoad)
      openWorkspaceWithEditor withFileExtension, (newEditor) -> editor = newEditor
      withDefaultProvider and runs ->
        provider = atom.packages.getActivePackage('you-complete-me').mainModule.provide()

  describe "Rust autocompletions", ->

    beforeEachFor('rust', 'rs', withDefaultProvider = false)
    beforeEach ->
      provider = getSuggestions: injector()

    it "detects rust files ", ->
      editor.setText("""
        use std::io;
        fn main() {

        }
      """)
      assertSuccessfulCompletions (result) ->
        expect(result.length).toBe 0
