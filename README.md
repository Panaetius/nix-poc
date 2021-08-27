Nix Composable Docker Images PoC
--------------------------------

`docker.nix` is a composed nix docker build script. It can be built using `nix-build docker.nix` and the result of that can be passed to `docker load` to get a docker image (or `docker load < $(nix-build docker.nix)`) to do it all in one go.

I tried to add the python package `deeplabcut`, as this doesn't exist in the nix package index.

The first attempt is in `deeplabcut.nix` which tries to build it from source. For this to work, all its requirements need to be added to the `propagatedBuildInputs` property in the file. The issue is that `wxPython` in the nix `20.09` package channel
doesn't build because its pyroma package is broken (pyroma itself had a bug). This would be fixed in the `21.05` channel, but that only only has python 3.8 and 3.9, not
3.7 as needed. So we'd also need to build pyroma manually using the fix in https://github.com/NixOS/nixpkgs/pull/134261 .

A second try was using `mach-nix gen -r requirements.txt` to automatically build
packages for deeplabcut and ALL its dependencies. This originally fails because
`wxPython` does not offer a linux package out of the box. In `dlc.nix` there is an
attempt to fix this with a modified wxPython package build that includes build
dependencies and uses patchelf to path c library dependencies, as wx needs
libjpeg.so.8 which nix doesn't have. This works for building though it fails
at runtime (the patched libjpeg is only patched in at build time but somehow
missing at runtime, no idea why). This approach needs `wxPython-4.1.1-cp37-cp37m-linux_x86_64.whl` from https://extras.wxpython.org/wxPython4/extras/linux/gtk3/ in the local directory to work.

The best approach to get it to work is probably backporting the pyroma fix to
the `deeplabcut.nix` file