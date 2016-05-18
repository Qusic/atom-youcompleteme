crypto = require 'crypto'
fs = require 'fs'
http = require 'http'
net = require 'net'
os = require 'os'
path = require 'path'
querystring = require 'querystring'
url = require 'url'
{BufferedProcess} = require 'atom'

utility = require './utility'

ycmdProcess = null
port = null
hmacSecret = null

launch = (exit) ->
  findUnusedPort = new Promise (fulfill, reject) ->
    net.createServer()
      .listen 0, ->
        result = this.address().port
        this.close()
        fulfill result
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

  processData = ([unusedPort, randomSecret, options]) -> new Promise (fulfill, reject) ->
    port = unusedPort
    hmacSecret = randomSecret
    options.hmac_secret = hmacSecret.toString 'base64'
    options[theirKey] = atom.config.get "you-complete-me.#{ourKey}" for theirKey, ourKey of {
      'global_ycm_extra_conf': 'globalExtraConfig'
      'confirm_extra_conf': 'confirmExtraConfig'
      'extra_conf_globlist': 'extraConfigGloblist'
      'rust_src_path': 'rustSrcPath'
    }
    optionsFile = path.resolve os.tmpdir(), "AtomYcmOptions-#{Date.now()}"
    fs.writeFile optionsFile, JSON.stringify(options), encoding: 'utf8', (error) ->
      unless error?
        fulfill optionsFile
      else
        reject error

  startServer = (optionsFile) -> new Promise (fulfill, reject) ->
    process = new BufferedProcess
      command: atom.config.get 'you-complete-me.pythonExecutable'
      args: [
        path.resolve atom.config.get('you-complete-me.ycmdPath'), 'ycmd'
        "--port=#{port}"
        "--options_file=#{optionsFile}"
        '--idle_suicide_seconds=600'
      ]
      options: {}
      stdout: (output) -> utility.debugLog 'CONSOLE', output
      stderr: (output) -> utility.debugLog 'CONSOLE', output
      exit: (code) ->
        exit()
        switch code
          when 3 then reject new Error 'Unexpected error while loading the YCM core library.'
          when 4 then reject new Error 'YCM core library not detected; you need to compile YCM before using it. Follow the instructions in the documentation.'
          when 5 then reject new Error 'YCM core library compiled for Python 3 but loaded in Python 2. Set the Python Executable config to a Python 3 interpreter path.'
          when 6 then reject new Error 'YCM core library compiled for Python 2 but loaded in Python 3. Set the Python Executable config to a Python 2 interpreter path.'
          when 7 then reject new Error 'YCM core library too old; PLEASE RECOMPILE by running the install.py script. See the documentation for more details.'
    setTimeout (-> fulfill process), 1000

  Promise.all [findUnusedPort, generateRandomSecret, readDefaultOptions]
    .then processData
    .then startServer

prepare = ->
  ycmdProcess ?= launch -> ycmdProcess = null

reset = ->
  realReset = (process) ->
    process?.kill?()
    ycmdProcess = null
    port = null
    hmacSecret = null
  Promise.resolve ycmdProcess
    .then realReset, realReset

request = (method, endpoint, parameters = null) -> prepare().then ->
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

  escapeUnicode = (string) ->
    escapedString = ''
    for i in [0...string.length]
      char = string.charAt i
      charCode = string.charCodeAt i
      escapedString += if charCode < 0x80 then char else ('\\u' + ('0000' + charCode.toString 16).substr -4)
    return escapedString

  handleException = (response) ->
    notifyException = ->
      atom.notifications.addWarning "[YCM] #{response.exception.TYPE}", detail: "#{response.message}\n#{response.traceback}"

    confirmExtraConfig = ->
      filepath = response.exception.extra_conf_file
      message = response.message
      atom.confirm
        message: '[YCM] Unknown Extra Config'
        detailedMessage: message
        buttons:
          Load: -> request('POST', 'load_extra_conf_file', {filepath}).catch utility.notifyError()
          Ignore: -> request('POST', 'ignore_extra_conf_file', {filepath}).catch utility.notifyError()

    shouldIgnore = ->
      response.message is 'File already being parsed.'

    if response?.exception?
      switch response.exception.TYPE
        when 'UnknownExtraConf' then confirmExtraConfig()
        else notifyException() unless shouldIgnore()

  Promise.resolve()
    .then ->
      requestMessage =
        hostname: 'localhost'
        port: port
        method: method
        path: url.resolve '/', endpoint
        headers: {}
      isPost = method is 'POST'
      requestPayload = ''
      if isPost
        requestPayload = escapeUnicode JSON.stringify parameters if parameters?
        requestMessage.headers['Content-Type'] = 'application/json'
        requestMessage.headers['Content-Length'] = requestPayload.length
      else
        requestMessage.path += "?#{querystring.stringify parameters}" if parameters?
      signMessage requestMessage, requestPayload
      return [requestMessage, isPost, requestPayload]

    .then ([requestMessage, isPost, requestPayload]) -> new Promise (fulfill, reject) ->
      requestHandler = http.request requestMessage, (responseMessage) ->
        responseMessage.setEncoding 'utf8'
        responsePayload = ''
        responseMessage.on 'data', (chunk) -> responsePayload += chunk
        responseMessage.on 'end', ->
          if verifyMessage responseMessage, responsePayload
            responseObject = try JSON.parse responsePayload catch error then responsePayload
            utility.debugLog 'REQUEST', method, endpoint, parameters
            utility.debugLog 'RESPONSE', responseObject
            handleException responseObject
            fulfill responseObject
          else
            reject new Error 'Bad Hmac'
      requestHandler.on 'error', (error) -> reject error
      requestHandler.write requestPayload if isPost
      requestHandler.end()

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

module.exports =
  prepare: prepare
  reset: reset
  request: request
