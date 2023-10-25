{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    typhon.url = "github:typhon-ci/typhon";
  };

  outputs = {
    self,
    nixpkgs,
    typhon,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};
    # libTyphon = typhon.actions.${system};
    mk = name: duration: {
      fails ? false,
      infinite ? false,
    }: let
      value = pkgs.stdenv.mkDerivation {
        inherit name;
        src = ./hello;
        configurePhase = ''
          echo '${name}'
          while true; do
            for i in $(seq 0 1 100); do
              printf "% 4d%s\n" $i '%'
              if [[ "$i" -eq "${
            if fails == false
            then "101"
            else toString fails
          }" ]]; then
                echo "failure" 1>&2
                exit 1
              fi
              sleep '${toString duration}'
            done
            echo "${
            if infinite
            then "repeting"
            else "compiling now"
          }"
          done
          export PREFIX=$out
        '';
      };
    in {inherit name value;};
  in {
    typhonProject = typhon.lib.github.mkGithubProject {
      owner = "W95Psp";
      repo = "typhon-test";
      secrets = null;
      typhon_url = "dummy";
    };
    typhonJobs."${system}" = pkgs.lib.listToAttrs [
      (mk "rustfmt" 0.5 {})
      (mk "check english" 0.3 {})
      (mk "tests" 2 {infinite = true;})
      (mk "build (debug)" 2.5 {infinite = true;})
      (mk "build" 1.5 {infinite = true;})
      (mk "more tests" 4 {fails = 95;})
      (mk "enforce 80 width" 0.1 {})
    ];
  };
}
