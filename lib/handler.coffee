crypto = require 'crypto'
fs = require 'fs'
http = require 'http'
net = require 'net'
os = require 'os'
path = require 'path'
querystring = require 'querystring'
url = require 'url'
{BufferedProcess} = require 'atom'

{jsonUnicodeEscaper} = require './utility'
debug = require './debug'

class YcmdLauncher
  constructor: (ycmdDirectory, @net=net, @fs=fs, @atom = atom,
                @BufferedProcess=BufferedProcess, @setTimeout=setTimeout) ->
    @waitForYcmdToStartInMilliseconds = 1000
    @idleSuicideSeconds = 600
    @resetWithYcmdDirectory(ycmdDirectory)

  resetWithYcmdDirectory: (@ycmdDirectory) ->
    @promise = null
    @process?.kill()
    @process = null
    this

  assureProcessHasStarted: ->
    return if @promise? and @process?.killed is false then @promise

    findUnusedPort = new Promise (fulfill, reject) =>
      @net.createServer()
        .listen 0, ->
          result = this.address().port
          this.close()
          fulfill result
        .on 'error', (error) ->
          reject error

    generateRandomSecret = new Promise (fulfill, reject) =>
      crypto.randomBytes 16, (error, data) ->
        unless error?
          fulfill data
        else
          reject error

    readDefaultOptions = new Promise (fulfill, reject) =>
      defaultOptionsFile = path.resolve @ycmdDirectory, 'ycmd', 'default_settings.json'
      @fs.readFile defaultOptionsFile, encoding: 'utf8', (error, data) ->
        unless error?
          fulfill JSON.parse data
        else
          reject error

    port = hmacSecret = null
    processData = ([unusedPort, randomSecret, options]) => new Promise (fulfill, reject) =>
      port = unusedPort
      hmacSecret = randomSecret
      options.hmac_secret = hmacSecret.toString 'base64'
      options.global_ycm_extra_conf = @atom.config.get 'you-complete-me.globalExtraConfig'
      optionsFile = path.resolve os.tmpdir(), "AtomYcmOptions-#{Date.now()}"
      @fs.writeFile optionsFile, JSON.stringify(options), encoding: 'utf8', (error) ->
        unless error?
          fulfill optionsFile
        else
          reject error

    startServer = (optionsFile) => new Promise (fulfill, reject) =>
      parameters =
        command: @atom.config.get 'you-complete-me.pythonExecutable'
        args: [
          path.resolve @ycmdDirectory, 'ycmd'
          "--port=#{port}"
          "--options_file=#{optionsFile}"
          "--idle_suicide_seconds=#{@idleSuicideSeconds}"
        ]
        options: {}
        exit: (status) => @process = null
      parameters.stdout = (output) -> debug.log 'CONSOLE STDOUT', output
      parameters.stderr = (output) -> debug.log 'CONSOLE STDERR', output
      @process = @BufferedProcess parameters
      @setTimeout( -> fulfill(['localhost', port, hmacSecret]),
      @waitForYcmdToStartInMilliseconds)

    @promise = Promise.all [findUnusedPort, generateRandomSecret, readDefaultOptions]
      .then processData
      .then startServer



class YcmdHandler
  constructor: (@ycmdLauncher,
                @http=http, @atom=atom) ->

  # TODO: remove
  resetYcmdPath: (newYcmdPath) =>
    @ycmdLauncher.resetWithYcmdDirectory newYcmdPath
    this


  request: (method, endpoint, parameters = null) => @ycmdLauncher.assureProcessHasStarted().then(
    ([hostname, port, hmacSecret]) ->
      generateHmac = (data, encoding) ->
        crypto.createHmac('sha256', hmacSecret).update(data).digest(encoding)

      verifyHmac = (data, hmac, encoding) ->
        secureCompare generateHmac(data, encoding), hmac

      secureCompare = (string1, string2) ->
        return false unless typeof string1 is 'string' and typeof string2 is 'string'
        return false unless string1.length is string2.length
        return Buffer.compare(generateHmac(string1), generateHmac(string2)) is 0

      signMessage = (message, payload) ->
        message.headers['X-Ycm-Hmac'] = generateHmac Buffer.concat([generateHmac(message.method), generateHmac(message.path), generateHmac(payload)]), 'base64'

      verifyMessage = (message, payload) ->
        verifyHmac payload, message.headers['x-ycm-hmac'], 'base64'

      handleException = (response) ->
        notifyException = ->
          @atom.notifications.addError "[YCM] #{response.exception.TYPE} #{response.message}", detail: if atom.inDevMode() then "#{response.traceback}" else null

        confirmExtraConfig = ->
          filepath = response.exception.extra_conf_file
          message = response.message
          @atom.confirm
            message: '[YCM] Unknown Extra Config'
            detailedMessage: message
            buttons:
              Load: -> request 'POST', 'load_extra_conf_file', {filepath}
              Ignore: -> request 'POST', 'ignore_extra_conf_file', {filepath}

        shouldIgnore = ->
          response.message is 'File already being parsed.'

        if response?.exception?
          switch response.exception.TYPE
            when 'UnknownExtraConf' then confirmExtraConfig()
            else notifyException() unless shouldIgnore()

      new Promise (fulfill, reject) ->
          requestMessage =
            hostname: hostname
            port: port
            method: method
            path: url.resolve '/', endpoint
            headers: {}
          isPost = method is 'POST'
          requestPayload = ''
          if isPost
            requestPayload = JSON.stringify parameters, jsonUnicodeEscaper if parameters?
            requestMessage.headers['Content-Type'] = 'application/json'
            requestMessage.headers['Content-Length'] = requestPayload.length
          else
            requestMessage.path += "?#{querystring.stringify parameters}" if parameters?
          signMessage requestMessage, requestPayload

          requestHandler = http.request requestMessage, (responseMessage) ->
            responseMessage.setEncoding 'utf8'
            responsePayload = ''
            responseMessage.on 'data', (chunk) -> responsePayload += chunk
            responseMessage.on 'end', ->
              if verifyMessage responseMessage, responsePayload
                responseObject = try JSON.parse responsePayload catch error then responsePayload
                debug.log 'REQUEST', method, endpoint, parameters
                debug.log 'RESPONSE', responseObject
                handleException responseObject
                fulfill responseObject
              else
                reject new Error 'Bad Hmac'
          requestHandler.on 'error', (error) -> reject error
          requestHandler.write requestPayload if isPost
          requestHandler.end()
   )
# API Endpoints:
#
# GET /ready
# GET /healthy
#
# POST /semantic_completion_available
# POST /completions
# POST /detailed_diagnostic
# POST /event_notification
#
# POST /defined_subcommands
# POST /run_completer_command
#
# GET /user_options
# POST /user_options
# POST /load_extra_conf_file
# POST /ignore_extra_conf_file
#
# POST /debug_info

# TODO: remove this
handler = new YcmdHandler(new YcmdLauncher atom.config.get('you-complete-me.legacyYcmdPath'))

module.exports =
  reset: handler.resetYcmdPath
  request: handler.request,
  YcmdHandler: YcmdHandler
  YcmdLauncher: YcmdLauncher
