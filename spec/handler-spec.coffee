{OnDemandYcmdLauncher} = require '../lib/handler'

describe "OnDemandYcmdLauncher", ->
  dummyDirectory = '/directory/of/ycmd/which/does/not/matter/here'
  defaultPort = 42

  class ServerMock
    constructor: ({@shouldFail}) ->
    listen: (_, listener) ->
      unless @shouldFail then listener.bind(this)()
      this
    address: -> port: defaultPort
    close: ->
    on: (eventName, handler) ->
      handler('failed to create server')

  readFileHandler = ({shouldFail}) -> (path, options, callback) ->
    expect(path).toMatch /default_settings\.json$/
    unless shouldFail then callback null, '{}' else callback 'error reading file'

  writeFileHandler = ({shouldFail}) -> (path, contents, options, callback) ->
    expect(path).toMatch /AtomYcmOptions-\d{13,}$/
    expect(options.encoding).toEqual 'utf8'
    if shouldFail then callback 'failed writing file' else callback()

  assertProcessParameters = (p) ->
    expect(p.args.length).toBe 4
    expect(p.args[0]).toMatch /\/ycmd$/
    expect(p.args[1]).toEqual "--port=#{defaultPort}"
    expect(p.args[2]).toMatch /^--options_file=/
    expect(p.args[3]).toMatch /^--idle_suicide_seconds=/

  beforeEach ->
    @atom = config: jasmine.createSpyObj 'config', ['get']
    @fs = jasmine.createSpyObj 'fs', ['readFile', 'writeFile']

    @fs.readFile.andCallFake readFileHandler(shouldFail: false)
    @fs.writeFile.andCallFake writeFileHandler(shouldFail: false)

    @net = jasmine.createSpyObj 'net', ['createServer']
    BufferedProcess = (p) ->
      assertProcessParameters p
      proc = jasmine.createSpyObj 'Process', ['kill']
      proc.killed = false
      proc

    @serverMock = new ServerMock(shouldFail: false)
    @net.createServer.andReturn @serverMock

    @launcher = new OnDemandYcmdLauncher(dummyDirectory, @net, @fs, @atom, BufferedProcess, (cb) -> cb())


  it "should start out without anything as it's lazy", ->
    expect(@launcher.promise).toBeNull()
    expect(@launcher.process).toBeNull()

  it "should attempt to kill its process when process directory is reset", ->
    @launcher.promise = 'dummy'
    process = jasmine.createSpyObj 'process', ['kill']
    @launcher.process = process

    @launcher.resetWithYcmdDirectory null

    expect(@launcher.promise).toBeNull()
    expect(@launcher.process).toBeNull()
    expect(process.kill).toHaveBeenCalled()

  it "fails if an unused port can't be found", ->
    @serverMock.shouldFail = true
    waitsForPromise shouldReject: true, => @launcher.assureProcessHasStarted()

  it "should try to read default options, and be able to fail gracefully", ->
    @fs.readFile.andCallFake readFileHandler(shouldFail: true)
    waitsForPromise shouldReject: true, => @launcher.assureProcessHasStarted()

  it "should try to write the file configuration file, and be able to fail gracefully", ->
    @fs.writeFile.andCallFake writeFileHandler(shouldFail: true)
    waitsForPromise shouldReject: true, => @launcher.assureProcessHasStarted()

  it "should launch a ycmd on first, then return existing process information", ->
    previousSecret = null
    waitsForPromise =>
      @launcher.assureProcessHasStarted().then ([hostname, port, hmacSecret]) ->
        expect(hostname).toEqual 'localhost'
        expect(port).toBe defaultPort
        expect(hmacSecret.length).toBe 16
        previousSecret = hmacSecret

    waitsForPromise =>
      @launcher.assureProcessHasStarted().then ([hostname, port, hmacSecret]) ->
          expect(hmacSecret).toBe previousSecret

describe 'YcmdLauncher', ->
  # TODO: test request
