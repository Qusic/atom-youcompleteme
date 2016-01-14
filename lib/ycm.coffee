{YcmdHandler, YcmdLauncher} = require './handler'
{autocompletePlusConfiguration, linterConfiguration} = require './provider'
{Menu} = require './menu'
{Dispatcher} = require './dispatch'
{FileStatusDB} = require './utility'
config = require './config'
lexer = require './lexer'


class Package
  ycmdPathFromConfig = -> atom.config.get('you-complete-me.legacyYcmdPath')

  constructor: (@fileDb = new FileStatusDB()
                @ycmdHandler = new YcmdHandler(new YcmdLauncher(ycmdPathFromConfig()))
                @dispatcher = new Dispatcher(@ycmdHandler, @fileDb)
                @menu = new Menu(@dispatcher)) ->

  activate: =>
    @subscriptions = atom.config.observe 'you-complete-me', @reset
    @menu.register()

  deactivate: =>
    @reset()
    @subscriptions?.dispose()
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

  provideSuggestions: -> autocompletePlusConfiguration(p.dispatcher)
  provideLinter: -> linterConfiguration(p.dispatcher, lexer)

  Package: Package
