module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
  ycmdPath:
    type: 'string'
    default: '/usr/lib/youcompleteme/third_party/ycmd'
  enabledScopes:
    type: 'string'
    default: '.source.c, .source.cpp, .source.objc, .source.objcpp'
  globalExtraConfig:
    type: 'string'
    default: 'ycm_extra_conf.py'
  lintDuringEdit:
    type: 'boolean'
    default: false
