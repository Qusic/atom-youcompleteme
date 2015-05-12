# Atom YouCompleteMe package

[AutoComplete+](https://github.com/atom-community/autocomplete-plus) Provider for [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)

## Previews

![](https://cloud.githubusercontent.com/assets/2141853/7228908/61ce58be-e790-11e4-967c-72884b50234e.png)
![](https://cloud.githubusercontent.com/assets/2141853/7228950/e1b39e0e-e790-11e4-866b-eea3e9d7ae0e.png)
![](https://cloud.githubusercontent.com/assets/2141853/7228947/cae4cc7a-e790-11e4-9542-3c1d94af6a07.png)
![](https://cloud.githubusercontent.com/assets/2141853/7228894/3555f788-e790-11e4-826a-5608d21ab94a.png)

## Usage

```
# Install the package
apm install you-complete-me

# Change directory to the bundled ycmd
cd ~/.atom/packages/you-complete-me/ycmd

# Build ycmd
git submodule update --init --recursive
./build.py --clang-completer --omnisharp-completer --gocode-completer
```

You may notice that this package uses a fork of ycmd instead of the original one. It is necessary for all the awesome features because the upstream does not merge pull requests quickly enough or some essential changes are specific to Atom client and will not be merged into the upstream.

Occasionally you have to rebuild ycmd after upgrading this package. In case that you are running into problems or not sure whether you have to rebuild it or not, run the script `ycmd.coffee` in the package and it will check it for you.

For detailed instructions and troubleshooting on building ycmd, see [YouCompleteMe's README](https://github.com/Valloric/YouCompleteMe/blob/master/README.md#installation).
