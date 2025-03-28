{ osConfig, ... }:

let
  inherit (osConfig.modules.display) monitors;
in
{
  wayland.windowManager.sway.config = {
    modifier = "Mod4"; # SUPER
    gaps.inner = 5;
    gaps.outer = 5;
    focus.followMouse = true;
    floating.modifier = "Mod4";
    workspaceAutoBackAndForth = true;
    assigns = builtins.listToAttrs (
      builtins.concatMap (
        m:
        map (w: {
          name = toString w;
          value = [ { output = m.name; } ];
        }) m.workspaces
      ) monitors
    );
    output = builtins.listToAttrs (
      map (m: {
        inherit (m) name;
        value = {
          inherit (m) scale;
          pos = m.position;
          mode = m.resolution;
        };
      }) monitors
    );
  };
}
