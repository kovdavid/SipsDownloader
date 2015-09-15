SipsDownloader
==============

Elixir module for downloading the ElixirSips episodes and all other files.

The login credentials, download location and login url must be set in config/config.exs.

The login url can be extracted from the form action from https://elixirsips.dpdcart.com/subscriber/content


## Installation

Clone this repository

```
git clone https://github.com/DavsX/SipsDownloader
cd SipsDownloader
```

Update config/config.exs, then generate an executable

```
mv config/config.exs.sample config/config.exs
mix escript.build
```

Run the executable

```
./sips_downloader
```
