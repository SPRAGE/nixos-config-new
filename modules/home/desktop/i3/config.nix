{ osConfig, ... }:

let
  inherit (osConfig.modules.display) monitors;
in
{
  xsession.windowManager.i3.config = {
    modifier = "Mod4";
    gaps = {
      inner = 10;
      outer = 10;
    };
    focus = {
      followMouse = true;
    };
    floating = {
      modifier = "Mod4";
    };

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
