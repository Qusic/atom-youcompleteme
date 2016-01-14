{YcmdHandler, YcmdLauncher} = require './handler'
provider = require './provider'
config = require './config'
{Menu} = require './menu'
{Dispatcher} = require './dispatch'
{FileStatusDB} = require './utility'


class Package
  ycmdPathFromConfig = -> atom.config.get('you-complete-me.legacyYcmdPath')

  constructor: (@fileDb = new FileStatusDB()
                @ycmdHandler = new YcmdHandler(new YcmdLauncher(ycmdPathFromConfig()))
                @dispatcher = new Dispatcher(@ycmdHandler, @fileDb),
                @menu = new Menu(@dispatcher)
                ) ->

  activate: =>
    @configObserver = atom.config.observe 'you-complete-me', @reset
    @menu.register()

  deactivate: =>
    @reset()
    @configObserver?.dispose()
    @menu?.deregister()
    @dispatcher?.dispose()
    @ycmdHandler?.ycmdLauncher.resetYcmdPath null

  reset: =>
    @ycmdycmdLauncher.resetYcmdPath ycmdPathFromConfig()
    @fileDb.clear()


p = new Package()

module.exports =
  config: config
  activate: p.activate
  deactivate: p.deactivate

  provide: -> provider
  provideLinter: -> provider

  Package: Package
