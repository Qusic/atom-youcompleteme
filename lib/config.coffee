module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
    order: 1
  ycmdPath:
    type: 'string'
    default: '/usr/lib/youcompleteme/third_party/ycmd'
    order: 2
  enabledFiletypes:
    type: 'string'
    default: 'c, cpp, objc, objcpp'
    order: 3
  globalExtraConfig:
    type: 'string'
    default: 'ycm_extra_conf.py'
    order: 4
