utility = require './utility'
getCompletions = require './get-completions'

module.exports =
  selector: '*'
  inclusionPriority: 2
  suggestionPriority: 2
  excludeLowerPriority: true
  filterSuggestions: false

  name: 'TabNine'
  grammarScopes: ['*']
  scope: 'file'
  lintsOnChange: false

  getSuggestions: (context) ->
    return [] unless utility.isEnabledForScope context.editor.getRootScopeDescriptor()
    getCompletions(context).catch utility.notifyError []

