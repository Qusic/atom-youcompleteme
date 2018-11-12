crypto = require 'crypto'
fs = require 'fs'
http = require 'http'
net = require 'net'
os = require 'os'
path = require 'path'
querystring = require 'querystring'
process = require 'process'
url = require 'url'
semver = require 'semver'
{BufferedProcess} = require 'atom'

utility = require './utility'

tabnine = null
port = null
secret = null

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

  processData = ([unusedPort, randomSecret]) -> new Promise (fulfill, reject) ->
    port = unusedPort
    secret = randomSecret
    options = { 'hmac_secret': secret.toString 'base64' }
    optionsFile = path.resolve os.tmpdir(), "HmacSecret-#{Date.now()}"
    fs.writeFile optionsFile, JSON.stringify(options), encoding: 'utf8', (error) ->
      unless error?
        fulfill optionsFile
      else
        reject error
  startServer = (optionsFile) -> new Promise (fulfill, reject) ->
    args = [
      "--port=#{port}"
      "--options_file=#{optionsFile}"
      '--idle_suicide_seconds=600'
    ]
    binary_root = path.join(__dirname, "..", "binaries")
    command = getBinaryPath(binary_root)
    process = new BufferedProcess
      command: command
      args: args
      stdout: (output) -> utility.debugLog 'CONSOLE', output
      stderr: (output) -> utility.debugLog 'CONSOLE', output
      exit: (code) ->
        port = null
        secret = null
        exit?()
    setTimeout (-> fulfill process), 1000

  Promise.all [findUnusedPort, generateRandomSecret]
    .then processData
    .then startServer

prepare = ->
  tabnine = Promise.resolve tabnine
    .catch (error) -> null
    .then (process) -> process or launch reset

reset = ->
  tabnine = Promise.resolve tabnine
    .catch (error) -> null
    .then (process) -> process?.kill()

request = (method, endpoint, parameters = null) -> prepare().then ->
  generateHmac = (data, encoding) ->
    crypto.createHmac('sha256', secret).update(data).digest(encoding)

  verifyHmac = (data, hmac, encoding) ->
    secureCompare generateHmac(data, encoding), hmac

  secureCompare = (string1, string2) ->
    return false unless typeof string1 is 'string' and typeof string2 is 'string'
    return false unless string1.length is string2.length
    return Buffer.compare(generateHmac(string1), generateHmac(string2)) is 0

  signMessage = (message, payload) ->
    message.headers['X-Ycm-Hmac'] = generateHmac Buffer.concat([generateHmac(message.method), generateHmac(message.path), generateHmac(payload)]), 'base64'

  verifyMessage = (message, payload) ->
    if payload.length == 0
      true
    else
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
      atom.notifications.addWarning "[TabNine] #{response.exception.TYPE}", detail: "#{response.message}\n#{response.traceback}"

    confirmExtraConfig = ->
      filepath = response.exception.extra_conf_file
      message = response.message
      atom.confirm
        message: '[TabNine] Unknown Extra Config'
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

getBinaryPath = (root) ->
  arch = switch process.arch
    when 'x32' then 'i686'
    else 'x86_64'
  platform = process.platform
  if platform == undefined
    platform = adHocGuessPlatform()
  suffix = switch platform
    when 'win32' then 'pc-windows-gnu/TabNine.exe'
    when 'darwin' then 'apple-darwin/TabNine'
    when 'linux' then 'unknown-linux-gnu/TabNine'
    else throw new Error("Sorry, the platform `#{process.platform}` is not supported by TabNine.")
  versions = fs.readdirSync(root)
  versions = sortBySemver(versions)
  tried = []
  for version in versions
    full_path = "#{root}/#{version}/#{arch}-#{suffix}"
    tried.push(full_path)
    if fs.existsSync(full_path)
      return full_path
  throw new Error("Couldn't find a TabNine binary (tried the following paths: #{tried})")

adHocGuessPlatform = () ->
  switch
    when fs.existsSync '/Applications' then 'darwin'
    when fs.existsSync '/home' then 'linux'
    else 'win32'

sortBySemver = (versions) ->
  cmp = (a, b) ->
    a_valid = semver.valid(a)
    b_valid = semver.valid(b)
    switch
      when a_valid && b_valid then semver.rcompare(a, b)
      when a_valid then -1
      when b_valid then 1
      when a < b then -1
      when a > b then 1
      else 0
  versions.sort(cmp)
  versions

module.exports = {
  prepare
  reset
  request
}
