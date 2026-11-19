{ pkgs }:
let
  trayIcon =
    pkgs.runCommand "bitwarden-grayscale-tray.png" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        magick ${pkgs.bitwarden-desktop.src}/apps/desktop/src/images/icon.png \
          -colorspace Gray "$out"
      '';
in
pkgs.bitwarden-desktop.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    # Use a separate asset: icon.png is also used by the application window.
    cp ${trayIcon} apps/desktop/src/images/icon-tray.png
    substituteInPlace apps/desktop/src/main/tray.main.ts \
      --replace-fail 'this.icon = path.join(__dirname, "/images/icon.png");' \
        'this.icon = path.join(__dirname, "/images/icon-tray.png");'

    # The login window uses Electron's system theme before Bitwarden preferences load.
    substituteInPlace apps/desktop/src/main/window.main.ts \
      --replace-fail 'import { app, BrowserWindow, ipcMain, nativeTheme, screen, session, protocol, net } from "electron";' \
        'import { app, BrowserWindow, ipcMain, nativeTheme, screen, session, protocol, net } from "electron";\nnativeTheme.themeSource = "dark";'
  '';
  passthru = (old.passthru or { }) // {
    sauceTrayIcon = trayIcon;
  };
})
