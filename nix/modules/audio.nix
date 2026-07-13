{ ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    wireplumber.extraConfig."51-bluez-avrcp" = {
      "wireplumber.settings" = {
        "bluez5.dummy-avrcp-player" = true;
      };
    };
  };
}
