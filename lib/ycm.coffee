handler = require './handler'
provider = require './provider'
config = require './config'
menu = require './menu'
dispatch = require './dispatch'
utility = require './utility'

configObserver = null

class Package
  ycmdPathFromConfig = -> atom.config.get('you-complete-me.legacyYcmdPath')

  constructor: (@ycmdHandler = new handler.YcmdHandler(ycmdPathFromConfig()),
                @fileDb = new utility.FileStatusDB()) ->

  activate: =>
    @configObserver = atom.config.observe 'you-complete-me', @reset

  deactivate: =>
    @reset()
    @configObserver?.dispose()
    @ycmdHandler.resetYcmdPath null

  reset: =>
    @ycmdHandler.resetYcmdPath ycmdPathFromConfig()
    @fileDb.clear()

activate = ->
  configObserver = atom.config.observe 'you-complete-me', handler.reset
  menu.register()

deactivate = ->
  configObserver?.dispose()
  menu.deregister()
  handler.reset()
  dispatch.dispose()

module.exports =
  config: config
  activate: activate
  deactivate: deactivate
  provide: -> provider
  provideLinter: -> provider
  Package: Package
