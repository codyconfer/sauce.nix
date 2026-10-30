# Selection keys match home/.chezmoi.toml.tmpl. Paths are resolved against pinned nixpkgs.
{
  tools = {
    "1password-cli" = [ "_1password-cli" ];
    aws = [ "awscli2" ];
    azure-cli = [ "azure-cli" ];
    bitwarden-cli = [ "bitwarden-cli" ];
    cloudflared = [ "cloudflared" ];
    gcloud = [ "google-cloud-sdk" ];
    gcx = null;
    wrangler = [ "wrangler" ];
    adb = [ "android-tools" ];
    claude-code = [ "claude-code" ];
    dotnet = [ "dotnet-sdk" ];
    go = [ "go" ];
    k9s = [ "k9s" ];
    kubectl = [ "kubectl" ];
    loglit = null;
    nvim = [ "neovim" ];
    # Nix-native replacement for the shell-downloaded nvm installer.
    nvm = [ "fnm" ];
    ollama = [ "ollama" ];
    opencode = [ "opencode" ];
    pi = [ "pi-coding-agent" ];
    poetry = [ "poetry" ];
    pyenv = [ "pyenv" ];
    rustup = [ "rustup" ];
    tmux = [ "tmux" ];
    yarn = [ "yarn" ];
    k3s = [ "k3s" ];
    docker = [ "docker" ];
    "llama.cpp" = [ "llama-cpp" ];
  };
  guiApps = {
    firefox = [ "firefox" ];
    sway = [ "sway" ];
    hyprland = [ "hyprland" ];
    alacritty = [ "alacritty" ];
    gnuradio = [ "gnuradio" ];
    qdmr = [ "qdmr" ];
    sourcegit = [ "sourcegit" ];
    vscode = [ "vscode" ];
    zed = [ "zed-editor" ];
    claude = null;
    codex = [ "codex" ];
    cursor = [ "code-cursor" ];
    docker = [ "docker" ];
    ghidra = [ "ghidra" ];
    jetbrains-toolbox = [ "jetbrains-toolbox" ];
    lmstudio = [ "lmstudio" ];
    obsidian = [ "obsidian" ];
    bitwarden = [ "bitwarden-desktop" ];
    "1password" = [ "_1password-gui" ];
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
