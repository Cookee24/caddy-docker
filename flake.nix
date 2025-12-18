{
  description = "Caddy with NaiveProxy and Cloudflare DNS plugins";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      caddyWithPlugins = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/caddy-dns/cloudflare@v0.2.2"
          "github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@naive"
        ];

        hash = "sha256-mvSn5T6K3BkDX8OJNfm5OpUYIpjSilPu19Y05mY3qjQ";
        doInstallCheck = false;
      };

      dockerImage = pkgs.dockerTools.buildLayeredImage {
        name = "caddy-cf-naive";
        tag = "latest";
        created = "now";

        contents = [
          caddyWithPlugins
          pkgs.cacert # Required for Let's Encrypt / ACME
          pkgs.iana-etc # Standard network files (/etc/protocols, etc.)
          pkgs.tzdata # Timezone data
        ];

        config = {
          Cmd = [
            "caddy"
            "run"
            "--config"
            "/etc/caddy/Caddyfile"
            "--adapter"
            "caddyfile"
          ];

          ExposedPorts = {
            "80/tcp" = { };
            "443/tcp" = { };
            "443/udp" = { }; # HTTP/3 (QUIC)
          };

          # Standard Caddy paths
          Env = [
            "XDG_CONFIG_HOME=/config"
            "XDG_DATA_HOME=/data"
          ];
          WorkingDir = "/var/lib/caddy";
          Volumes = {
            "/config" = { };
            "/data" = { };
          };
        };
      };
    in
    {
      packages.${system} = {
        default = dockerImage;
        caddy = caddyWithPlugins;
      };
    };
}
