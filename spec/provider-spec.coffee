{autocompletePlusConfiguration} = require '../lib/provider'

describe "Provider", ->
  describe "autocompletePlusConfiguration()", ->
    pc = autocompletePlusConfiguration
    beforeEach ->
      @suggestions = jasmine.createSpy('getSuggestions')
      @lints = jasmine.createSpy('getCompileEvents')
      @p = pc @suggestions, @lints

    it "configure a selector based on enabled languages", ->
      supportsRust = true
      spyOn(atom.config, 'get').andCallFake (key) ->
        return supportsRust if key == 'you-complete-me.rust'
        false

      expect(pc().selector).toContain 'rust'

      supportsRust = false
      expect(pc().selector).not.toContain 'rust'

    it "should convert suggestion errors to an empty array", ->
      # TODO

  describe "linterConfiguration()", ->
    # TODO

    it "should convert lint errors to an empty array", ->
      # TODO
