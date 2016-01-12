{Dispatcher} = require '../lib/dispatch'
{FileStatusDB, getEditorData} = require '../lib/utility'
{singleEditorWith} = require './utility'
atom = require 'atom'

describe "Dispatcher", ->
  class FakeHandler
    constructor: (@promiseError, @responseException) ->
    setShouldFailRequestWithError: (@promiseError) ->
    setResponseException: (@responseException='some error') ->
    request: (type, eventName, parameters) ->
      new Promise (fulfill, reject) =>
        if @promiseError? then return reject @promiseError
        fulfill exception: @responseException

  beforeEach ->
    singleEditorWith fileExtension='c', content="int x = 42;", (editor) => @editor = editor

    waitsForPromise =>
      getEditorData @editor
        .then (@context) =>

    runs =>
      handler = new FakeHandler
      spyOn(handler, 'request').andCallThrough()

      compositeDisposable = new atom.CompositeDisposable()
      spyOn(compositeDisposable, 'dispose')

      @context.editor = @editor
      @d = new Dispatcher(handler, new FileStatusDB(), compositeDisposable)

  describe "processReady()", ->
    fit "should mark a file as firstready if everything is good", ->
      waitsForPromise =>
        @d.processReady @context
          .then (response) =>
            status = (status) => @d.fileStatusDb.getStatus @context.editor.getPath(), status
            expect(status 'ready').toBe false
            expect(status 'firstready').toBe true

    it "disposes its callbacks on dispose", ->
      @d.dispose()
      expect(@d.dispatchDispose.dispose).toHaveBeenCalled()
