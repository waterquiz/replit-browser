{pkgs}: {
  deps = [
    pkgs.python312Packages.websockify
    pkgs.python3
    pkgs.xdotool
    pkgs.openbox
    pkgs.chromium
    pkgs.x11vnc
    pkgs.xvfb-run
    pkgs.xorg.xorgserver
  ];
}
