# Atom YouCompleteMe package

[AutoComplete+](https://github.com/atom-community/autocomplete-plus) Provider for [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

## Previews

![](https://cloud.githubusercontent.com/assets/2141853/7626423/79024212-fa3b-11e4-941e-e014a8e5b0df.gif)
![](https://cloud.githubusercontent.com/assets/2141853/7626422/7901f352-fa3b-11e4-8007-82ab514fb8e9.gif)

## Usage

```
# Install the package
apm install you-complete-me

# Change directory to the package
cd ~/.atom/packages/you-complete-me

# Fetch and build ycmd
./ycmd.coffee
./ycmd/build.py --clang-completer --omnisharp-completer --gocode-completer
```

You may notice that this package uses a fork of ycmd instead of the original one. It is necessary for all the awesome features because the upstream does not merge pull requests quickly enough or some essential changes are specific to Atom client and will not be merged into the upstream.

Occasionally you have to rebuild ycmd after upgrading this package. In case that you are running into problems or not sure whether you have to rebuild it or not, run the script `ycmd.coffee` in the package and it will check it for you.

For detailed instructions and troubleshooting on building ycmd, see [YouCompleteMe's README](https://github.com/Valloric/YouCompleteMe/blob/master/README.md#installation).
