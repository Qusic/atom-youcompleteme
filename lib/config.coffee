module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
    order: 3
  globalExtraConfig:
    type: 'string'
    default: 'ycm_extra_conf.py'
    order: 2
  legacyYcmdPath:
    type: 'string'
    title: 'Path of ycmd server'
    order: 1
  lintDuringEdit:
    type: 'boolean'
    default: false
    order: 7
  pythonSupport:
    type: 'boolean'
    default: true
    order: 4
  csharpSupport:
    type: 'boolean'
    default: true
    order: 5
  golangSupport:
    type: 'boolean'
    default: true
    order: 6
  forceComplete:
    type: 'boolean'
    default: false
    description: 'Force trigger compelete every time instead of identifier compelete (too slow)'
    order: 8
