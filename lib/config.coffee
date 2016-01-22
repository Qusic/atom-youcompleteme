module.exports =
  pythonExecutable:
    type: 'string'
    default: 'python'
    order: 1
    description: 'A path to the python executable to launch the ycmd server process with.
      It will be used to start the *ycmd*.'
  ycmdPath:
    type: 'string'
    default: '/usr/lib/youcompleteme/third_party/ycmd'
    order: 2
    description: 'The directory containing the `ycmd/default_settings.json` file.
      [Ycmd](https://github.com/Valloric/ycmd) is required for this plugin to work.'
  enabledFiletypes:
    type: 'string'
    default: 'c, cpp, objc, objcpp'
    order: 3
    description: 'A comma-separated list of file-types within we should provide suggestions.
    They are equivalent to file-extensions most of the time.'
  globalExtraConfig:
    type: 'string'
    default: ''
    order: 4
    description: 'Follow
      [-> this link <-](https://github.com/Valloric/YouCompleteMe#the-gycm_global_ycm_extra_conf-option)
      for more information.'
  rustSrcPath:
    type: 'string'
    default: ''
    order: 5
    description: 'The directory containing the
      [-> Rust source code <-](https://github.com/rust-lang/rust),
      e.g. `/path/to/rust-lang/rust/src`.
      You have to to add the `rust` file extension in **Enabled Filetypes** to see the effect.'
