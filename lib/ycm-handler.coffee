crypto = require 'crypto'
fs = require 'fs'
http = require 'http'
net = require 'net'
os = require 'os'
path = require 'path'
querystring = require 'querystring'
url = require 'url'
{BufferedProcess} = require 'atom'

module.exports =
  ycmdProcess: null
  port: null
  hmacSecret: null

  prepare: ->
    findUnusedPort = new Promise (fulfill, reject) ->
      net.createServer()
        .listen 0, () ->
          port = @address().port
          @close()
          fulfill port
        .on 'error', (error) ->
          reject error
    generateRandomSecret = new Promise (fulfill, reject) ->
      crypto.randomBytes 16, (error, data) ->
        unless error?
          fulfill data
        else
          reject error
    readDefaultOptions = new Promise (fulfill, reject) ->
      defaultOptionsFile = path.resolve atom.config.get('you-complete-me.ycmdPath'), 'ycmd', 'default_settings.json'
      fs.readFile defaultOptionsFile, encoding: 'utf8', (error, data) ->
        unless error?
          fulfill JSON.parse data
        else
          reject error
    processData = ([port, hmacSecret, options]) => new Promise (fulfill, reject) =>
      @port = port
      @hmacSecret = hmacSecret
      options.hmac_secret = hmacSecret.toString 'base64'
      options.global_ycm_extra_conf = atom.config.get 'you-complete-me.globalExtraConfig'
      optionsFile = path.resolve os.tmpdir(), "AtomYcmOptions-#{Date.now()}"
      fs.writeFile optionsFile, JSON.stringify(options), encoding: 'utf8', (error) ->
        unless error?
          fulfill optionsFile
        else
          reject error
    launchServer = (optionsFile) => new Promise (fulfill, reject) =>
      pythonExecutable = path.resolve atom.config.get 'you-complete-me.pythonExecutable'
      ycmdPath = path.resolve atom.config.get('you-complete-me.ycmdPath'), 'ycmd'
      @ycmdProcess = new BufferedProcess
        command: pythonExecutable
        args: [
          ycmdPath
          "--port=#{@port}"
          "--options_file=#{optionsFile}"
          '--idle_suicide_seconds=600'
        ]
        options: {}
        stdout: (output) -> console.log '[YCM-CONSOLE]', output
        stderr: (output) -> console.log '[YCM-CONSOLE]', output
        exit: (status) => @ycmdProcess = null
      fulfill()
    Promise.all [findUnusedPort, generateRandomSecret, readDefaultOptions]
      .then processData
      .then launchServer

  reset: ->
    @ycmdProcess?.kill()
    @ycmdProcess = null
    @port = null
    @hmacSecret = null
    Promise.resolve()

  prepareIfNecessary: ->
    if @ycmdProcess?.killed is false
      Promise.resolve()
    else
      @prepare()

  request: (method, endpoint, parameters = null) -> @prepareIfNecessary().then =>
    generateHmac = (data, encoding) =>
      crypto.createHmac('sha256', @hmacSecret).update(data).digest(encoding)
    verifyHmac = (data, hmac, encoding) ->
      secureCompare generateHmac(data, encoding), hmac
    secureCompare = (string1, string2) ->
      return false unless typeof string1 is 'string' and typeof string2 is 'string'
      return false unless string1.length is string2.length
      return Buffer.compare(generateHmac(string1), generateHmac(string2)) is 0
    signRequest = (request, data) ->
      request.headers['X-Ycm-Hmac'] = generateHmac Buffer.concat([generateHmac(request.method), generateHmac(request.path), generateHmac(data)]), 'base64'
    verifyResponse = (response, data) ->
      verifyHmac data, response.headers['x-ycm-hmac'], 'base64'
    Promise.resolve()
      .then () =>
        options =
          hostname: 'localhost'
          port: @port
          method: method
          path: url.resolve '/', endpoint
          headers: {}
        isPost = method is 'POST'
        postData = ''
        if isPost
          postData = JSON.stringify parameters if parameters?
          options.headers['Content-Type'] = 'application/json'
          options.headers['Content-Length'] = postData.length
        else
          options.path += "?#{querystring.stringify parameters}" if parameters?
        signRequest options, postData
        return [options, isPost, postData]
      .then ([options, isPost, postData]) -> new Promise (fulfill, reject) ->
        request = http.request options, (response) ->
          response.setEncoding 'utf8'
          data = ''
          response.on 'data', (chunk) -> data += chunk
          response.on 'end', () ->
            if verifyResponse response, data
              object = JSON.parse data
              console.log '[YCM-REQUEST]', method, endpoint, parameters
              console.log '[YCM-RESPONSE]', object
              fulfill object
            else
              reject new Error 'Bad Hmac'
        request.on 'error', (error) -> reject error
        request.write postData if isPost
        request.end()

  # API Endpoints:
  #
  # isReady: () -> @request 'GET', 'ready'
  # isHealthy: () -> @request 'GET', 'healthy'
  #
  # isSemanticCompletionAvailable: () -> @request 'POST', 'semantic_completion_available'
  # getCompletions: () -> @request 'POST', 'completions'
  # getDetailedDiagnostic: () -> @request 'POST', 'detailed_diagnostic'
  # sendEventNotification: () -> @request 'POST', 'event_notification'
  #
  # getDefinedSubcommands: () -> @request 'POST', 'defined_subcommands'
  # runCompleterCommand: () -> @request 'POST', 'run_completer_command'
  #
  # getUserOptions: () -> @request 'GET', 'user_options'
  # setUserOptions: () -> @request 'POST', 'user_options'
  # loadExtraConfFile: () -> @request 'POST', 'load_extra_conf_file'
  # ignoreExtraConfFile: () -> @request 'POST', 'ignore_extra_conf_file'
  #
  # getDebugInfo: () -> @request 'POST', 'debug_info'
