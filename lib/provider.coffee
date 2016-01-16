getSuggestions = require './get-suggestions'
getCompileEvents = require './get-compile-events'

module.exports =
  selector: atom.config.get('you-complete-me.enabledScopes')
  inclusionPriority: 2
  suggestionPriority: 2
  excludeLowerPriority: false

  grammarScopes: atom.config.get('you-complete-me.enabledScopes').split(',').map (scope) -> scope.trim().replace(/^\./, '')
  scope: 'file'
  lintOnFly: atom.config.get 'you-complete-me.lintDuringEdit'

  getSuggestions: (context) ->
    getSuggestions(context).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []

  lint: (editor) ->
    getCompileEvents(editor).catch (error) ->
      console.error '[YCM-ERROR]', error
      return []
