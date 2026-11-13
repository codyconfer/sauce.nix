{
  tools = {
    aws = [ "awscli2" ];
    azure-cli = [ "azure-cli" ];
    bitwarden-cli = [ "bitwarden-cli" ];
    gcloud = [ "google-cloud-sdk" ];
    gcx = [ "gcx" ];
    wrangler = [ "wrangler" ];
    adb = [ "android-tools" ];
    claude-code = [ "claude-code" ];
    dotnet = [ "dotnet-sdk" ];
    go = [ "go" ];
    k9s = [ "k9s" ];
    kubectl = [ "kubectl" ];
    loglit = null;
    nvim = [ "neovim" ];
    nvm = null; # Shell integration is provided by modules/shell.nix.
    opencode = [ "opencode" ];
    pi = [ "pi-coding-agent" ];
    poetry = [ "poetry" ];
    pyenv = [ "pyenv" ];
    pnpm = [ "pnpm" ];
    rustup = [ "rustup" ];
    tmux = [ "tmux" ];
    k3s = [ "k3s" ];
    docker = [ "docker" ];
    "llama.cpp" = [ "llama-cpp" ];
  };
  guiApps = {
    firefox = [ "firefox" ];
    remmina = [ "remmina" ];
    sway = [ "sway" ];
    alacritty = [ "alacritty" ];
    foot = [ "foot" ];
    gnuradio = [ "gnuradio" ];
    sdrpp = [ "sdrpp" ];
    gqrx = [ "gqrx" ];
    qdmr = [ "qdmr" ];
    sourcegit = [ "sourcegit" ];
    vscode = [ "vscode" ];
    zed = [ "zed-editor" ];
    codex = [ "codex" ];
    cursor = [ "code-cursor" ];
    docker = [ "docker" ];
    podman-desktop = [ "podman-desktop" ];
    ghidra = [ "ghidra" ];
    jetbrains-toolbox = [ "jetbrains-toolbox" ];
    lmstudio = [ "lmstudio" ];
    obsidian = [ "obsidian" ];
    typora = [ "typora" ];
    libreoffice = [ "libreoffice" ];
    affinity = [ "affinity-v3" ];
    reaper = [ "reaper" ];
    nam = [ "neural-amp-modeler-lv2" ];
    guitarix = [ "guitarix" ];
    byod = null; # Provided by a local package override.
    ardour = [ "ardour" ];
    lmms = [ "lmms" ];
    zrythm = [ "zrythm" ];
    qtractor = [ "qtractor" ];
    helio = [ "helio-workstation" ];
    gimp = [ "gimp" ];
    kdenlive = [
      "kdePackages"
      "kdenlive"
    ];
    shotcut = [ "shotcut" ];
    davinci-resolve = [ "davinci-resolve" ];
    bitwarden = [ "bitwarden-desktop" ];
  };
  media = {
    vlc = [ "vlc" ];
    audacious = [ "audacious" ];
    quodlibet = [ "quodlibet" ];
    ffmpeg = [ "ffmpeg" ];
  };
  emulators = {
    steam = [ "steam" ];
    wine = [
      "wineWow64Packages"
      "stable"
    ];
    qemu = [ "qemu" ];
  };
  flatpaks = {
    slack = "com.slack.Slack";
    discord = "com.discordapp.Discord";
    signal = "org.signal.Signal";
    easyeffects = "com.github.wwmm.easyeffects";
    obs-studio = "com.obsproject.Studio";
    zen = "app.zen_browser.zen";
    lutris = "net.lutris.Lutris";
    retroarch = "org.libretro.RetroArch";
    zoom = "us.zoom.Zoom";
    chirp = "com.chirpmyradio.chirp";
    sonic-pi = "net.sonic_pi.SonicPi";
  };
}
