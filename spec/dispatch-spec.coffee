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

  fdescribe "processReady()", ->
    status = (_this, status) -> _this.d.fileStatusDb.getStatus _this.context.editor.getPath(), status

    it "should mark a file as firstready if everything is good", ->
      waitsForPromise =>
        @d.processReady @context
          .then (response) =>
            expect(status this, 'ready').toBe false
            expect(status this, 'firstready').toBe true

    for [errorDescription, expectRejection, enableError] in [
      ["response has exception", false, (h) -> h.setResponseException 'exception in response']
      ["response failed entirely", true, (h) -> h.setShouldFailRequestWithError 'network failure']
    ]
      ((enableError, expectRejection) ->
        it "should not mark it as firstready if " + errorDescription, ->
          console.log expectRejection, errorDescription
          enableError @d.handler
          waitsForPromise shouldReject: expectRejection, =>
            @d.processReady @context
              .then (response) =>
                expect(status this, 'ready').toBe false
                expect(status this, 'firstready').toBeFalsy()
        )(enableError, expectRejection)

    it "disposes its callbacks on dispose", ->
      @d.dispose()
      expect(@d.dispatchDispose.dispose).toHaveBeenCalled()
