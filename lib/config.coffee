module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
    order: 1
    description: 'A path to the python executable to launch the ycmd server process with.'
  ycmdPath:
    type: 'string'
    default: '/usr/lib/youcompleteme/third_party/ycmd'
    order: 2
    description: 'The directory containing the `ycmd/default_settings.json` file.'
  enabledFiletypes:
    type: 'string'
    default: 'c, cpp, objc, objcpp'
    order: 3
    description: 'A comma-separated list of file-extensions within we should provide suggestions.'
  globalExtraConfig:
    type: 'string'
    default: ''
    order: 4
    description: 'Additional configuration for ycmd. Follow
      [-> this link <-](https://github.com/Valloric/YouCompleteMe#the-gycm_global_ycm_extra_conf-option)
      for more information.'
  rustSrcPath:
    type: 'string'
    default: ''
    order: 5
    description: 'The directory containing the Rust source code, e.g. `/path/to/rust-lang/rust/src`.
      You have to to add the `rs` file extension in **Enabled Filetypes** and restart atom
      for it to become active.'
