path = require 'path'

module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
  globalExtraConfig:
    type: 'string'
    default: 'ycm_extra_conf.py'
  legacyYcmdPath:
    type: 'string'
    title: 'Path of ycmd server'
    default: path.resolve atom.packages.resolvePackagePath('you-complete-me'), 'ycmd'
  lintDuringEdit:
    type: 'boolean'
    default: false
  pythonSupport:
    type: 'boolean'
    default: true
  csharpSupport:
    type: 'boolean'
    default: true
  golangSupport:
    type: 'boolean'
    default: true
