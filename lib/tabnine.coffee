{install} = require 'atom-package-deps'

provider = require './provider'
handler = require './handler'
event = require './event'

activate = ->
  install('TabNine', true)
  event.register()

deactivate = ->
  event.deregister()
  handler.reset()

module.exports = {
  activate
  deactivate
  provide: -> provider
}
