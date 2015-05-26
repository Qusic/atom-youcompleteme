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
  ycmdPath: path.resolve atom.packages.resolvePackagePath('you-complete-me'), 'ycmd'
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

    readDefaultOptions = new Promise (fulfill, reject) =>
      defaultOptionsFile = path.resolve @ycmdPath, 'ycmd', 'default_settings.json'
      fs.readFile defaultOptionsFile, encoding: 'utf8', (error, data) ->
        unless error?
          fulfill JSON.parse data
        else
          reject error

    processData = ([port, hmacSecret, options]) => new Promise (fulfill, reject) =>
      @port = port
      @hmacSecret = hmacSecret
      options.hmac_secret = hmacSecret.toString 'base64'
      globalConf = atom.config.get 'you-complete-me.globalExtraConfig'
      if globalConf
          # use provided
          options.global_ycm_extra_conf = globalConf
      else
          # use default project/.ycm_extra_conf.py
          projPath = atom.project.getPaths()[0]
          if projPath
              options.global_ycm_extra_conf = path.join(atom.project.getPaths()[0], '.ycm_extra_conf.py')
          else
              # no project, no luck
              options.global_ycm_extra_conf = ''

      optionsFile = path.resolve os.tmpdir(), "AtomYcmOptions-#{Date.now()}"
      fs.writeFile optionsFile, JSON.stringify(options), encoding: 'utf8', (error) ->
        unless error?
          fulfill optionsFile
        else
          reject error

    launchServer = (optionsFile) => new Promise (fulfill, reject) =>
      parameters =
        command: atom.config.get 'you-complete-me.pythonExecutable'
        args: [
          path.resolve @ycmdPath, 'ycmd'
          "--port=#{@port}"
          "--options_file=#{optionsFile}"
          '--idle_suicide_seconds=600'
        ]
        options: {}
        exit: (status) => @ycmdProcess = null
      if atom.inDevMode()
        parameters.stdout = (output) -> console.debug '[YCM-CONSOLE]', output
        parameters.stderr = (output) -> console.debug '[YCM-CONSOLE]', output
      @ycmdProcess = new BufferedProcess parameters
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

    unicodeEscaper = (key, value) ->
      if typeof value is 'string'
        escapedString = ''
        for i in [0...value.length]
          char = value.charAt i
          charCode = value.charCodeAt i
          escapedString += if charCode < 0x80 then char else "\\u#{"0000#{charCode.toString 16}".substr -4}"
        return escapedString
      else
        return value

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
          postData = JSON.stringify parameters, unicodeEscaper if parameters?
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
              if atom.inDevMode()
                console.debug '[YCM-REQUEST]', method, endpoint, parameters
                console.debug '[YCM-RESPONSE]', object
              fulfill object
            else
              reject new Error 'Bad Hmac'
        request.on 'error', (error) -> reject error
        request.write postData if isPost
        request.end()

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
  #
  # Only available on Qusic's ycmd fork:
  # POST /atom_completions
