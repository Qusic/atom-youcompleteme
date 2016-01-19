{getSuggestions} = require './get-suggestions'
{getCompileEvents} = require './get-compile-events'

autocompletePlusConfiguration = (dispatcher, lexer, suggestionsFor = getSuggestions) ->
  name: 'YCM Autocomplete Provider'
  selector: (
    langs = ['.source.c', '.source.cpp', '.source.objc', '.source.objcpp']
    for {lang, supportLang} in [
      {lang: 'python'}
      {lang: 'cs', supportLang: 'csharp'}
      {lang: 'go', supportLang: 'golang'}
      {lang: 'rust'}
      ]
      configKey = 'you-complete-me.' + (supportLang ? lang)
      langs.push('.source.' + lang) if not atom.config.get(configKey)? or
                                           atom.config.get configKey

    langs.join ','
  )
  disableForSelector: '.source.c .comment, .source.cpp .comment, .source.objc .comment, .source.objcpp .comment, .source.python .comment, .source.cs .comment, .source.go .comment .source.rust.comment'
  inclusionPriority: 1
  excludeLowerPriority: false

  getSuggestions: (context) ->
    suggestionsFor(context, dispatcher, lexer).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []

  dispose: ->
    # nothing for now !

linterConfiguration = (dispatcher, compileEventsFor = getCompileEvents) ->
  name: 'YCM Linter'
  grammarScopes: (
    langs = ['source.c', 'source.cpp', 'source.objc', 'source.objcpp']
    langs.push('source.cs') if not atom.config.get('you-complete-me.csharpSupport')? or atom.config.get 'you-complete-me.csharpSupport'
    langs
  )
  scope: 'file' # or 'project'
  lintOnFly: atom.config.get 'you-complete-me.lintDuringEdit' # must be false for scope: 'project'

  lint: (editor) ->
    compileEventsFor(editor, dispatcher).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []


module.exports =
  autocompletePlusConfiguration: autocompletePlusConfiguration
  linterConfiguration: linterConfiguration
