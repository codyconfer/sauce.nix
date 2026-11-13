{ lib, ... }:
{
  sauce = {
    guiApps = lib.mkDefault [
      "gnuradio"
      "sdrpp"
      "gqrx"
      "qdmr"
    ];
    flatpaks = lib.mkDefault [ "chirp" ];
  };
}
