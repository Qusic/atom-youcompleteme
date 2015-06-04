log = (category, message...) ->
  console.debug "[YCM-#{category}]", message... if atom.inDevMode()

module.exports =
  log: log
