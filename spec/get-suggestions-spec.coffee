{getSuggestions} = require '../lib/get-suggestions'
{assurePluginLoadedWithLanguage, openWorkspaceWithEditor} = require './utility'

describe "get-suggestions", ->
  assert = (_this) -> (assertionCallback) ->
    waitsForPromise ->
      getCompletions _this.editor, _this.dispatcher, _this.lexer
        .then assertionCallback

  getCompletions = (editor, dispatcher, lexer) ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])

    request =
      editor: editor
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    getSuggestions(request, dispatcher, lexer)

  beforeEachFor = (languageToLoad, withFileExtension, withDefaultProvider = true) ->
    beforeEach ->
      assurePluginLoadedWithLanguage(languageToLoad)
      openWorkspaceWithEditor withFileExtension, (newEditor) => @editor = newEditor
      withDefaultProvider and runs ->
        provider = atom.packages.getActivePackage('you-complete-me').mainModule.provide()


  beforeEachFor 'rust', 'rs', withDefaultProvider = false
  beforeEach ->
    # TODO: setup actual mocks
    @dispatcher = jasmine.createSpyObj 'Dispatcher', ['foo']
    @lexer = jasmine.createSpyObj 'lexer', ['bar']
    @assert = assert(this)


  it "detects rust files ", ->
    @editor.setText("""
      use std::io;
      fn main() {

      }
    """)
    @assert (result) ->
      expect(result.length).toBe 0
