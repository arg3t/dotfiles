{ pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true;
        DeviceID = "bluetooth:004C:0000:0000";
      };
    };
  };

  services.blueman.enable = true;

#  environment.systemPackages = with pkgs; [
#  ];
}
