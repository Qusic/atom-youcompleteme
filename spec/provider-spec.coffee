{autocompletePlusConfiguration} = require '../lib/provider'
{dispatcherMock} = require './utility'

describe "Provider", ->
  describe "autocompletePlusConfiguration()", ->
    pc = autocompletePlusConfiguration
    beforeEach ->
      @dispatcher = dispatcherMock()
      @lexer = jasmine.createSpy('lexer');
      @p = pc @dispatcher, @lexer

    it "configures a selector based on enabled languages", ->
      supportsRust = true
      spyOn(atom.config, 'get').andCallFake (key) ->
        return supportsRust if key == 'you-complete-me.rust'
        false

      expect(pc().selector).toContain 'rust'

      supportsRust = false
      expect(pc().selector).not.toContain 'rust'

    describe "error handling", ->
      beforeEach ->
        @context =
          editor: jasmine.createSpyObj('editor', ['getPath'])

        @context.editor.getPath.andReturn "some/path"
        @dispatcher.processBefore.andCallFake -> -> throw new Error('cannot do that')
        spyOn(console, 'error')

      it "can handle errors by printing to console and returning []", ->
        waitsForPromise =>
          @p.getSuggestions @context
            .then (value) ->
              expect(value).toEqual []
              expect(console.error.calls.length).toBe 1
              expect(console.error.mostRecentCall.args[1].message).toEqual 'cannot do that'


  describe "linterConfiguration()", ->
    # TODO

    it "should convert lint errors to an empty array", ->
      # TODO
