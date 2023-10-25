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
    libTyphon = typhon.actions.${system};
    mk = name: duration: fails: let
      value = pkgs.stdenv.mkDerivation {
        inherit name;
        src = ./hello;
        configurePhase = ''
          echo '${name}'
          for i in $(seq 0 1 100); do
            printf "% 4d%s\n" $i '%'
            if [[ "$i" -eq '${fails}' ]];
              echo "failure" 1>&2
              exit 1
            done
            sleep '${toString duration}'
          done
          export PREFIX=$out
        '';
      };
    in {inherit name value;};
  in {
    typhonProject = libTyphon.mkProject {
      meta = {
        title = "Test";
        description = "testing Typhon";
        homepage = "https://typhon-ci.org";
      };
      actions = {
        jobsets = libTyphon.mkGitJobsets {url = "/home/lucas/repos/typhon-test";};
      };
    };
    typhonJobs =
      (pkgs.lib.listToAttrs [
        (mk "rustfmt" 0.5 false)
        (mk "check english" 0.3 false)
        (mk "tests" 2 false)
        (mk "build" 1.5 false)
        (mk "more tests" 4 95)
        (mk "enforce 80 width" 0.1 false)
      ])
      // {
        # dev = make {name = "dev"; duration = 0.5;};
        # feature-foo = make {name = "feature-one"; duration = 0.5;};
      };
  };
}
