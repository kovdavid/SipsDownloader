SipsDownloader
==============

Elixir module for downloading the ElixirSips episodes and all other files.

The login credentials and download location must be set in config/config.exs.

## Installation

Clone this repository

```
git clone https://github.com/DavsX/SipsDownloader
cd SipsDownloader
```

Update config/config.exs, then generate an executable

```
mv config/config.exs.sample config/config.exs
vim config/config.exs
mix escript.build
```

Run the executable

```
./sips_downloader
```
