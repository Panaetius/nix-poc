{ pkgs, python, ... }:
with builtins;
with pkgs.lib;
let
  pypi_fetcher_src = builtins.fetchTarball {
    name = "nix-pypi-fetcher";
    url = "https://github.com/DavHau/nix-pypi-fetcher/tarball/e105186d0101ead100a64e86b1cd62abd1482e62";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0nyil3npbqhwgqmxp65s3zn0hgisx14sjyv70ibbbdimfzwvy5qv";
  };
  pypiFetcher = import pypi_fetcher_src { inherit pkgs; };
  fetchPypi = pypiFetcher.fetchPypi;
  fetchPypiWheel = pypiFetcher.fetchPypiWheel;
  is_py_module = pkg:
    isAttrs pkg && hasAttr "pythonModule" pkg;
  normalizeName = name: (replaceStrings ["_"] ["-"] (toLower name));
  replace_deps = oldAttrs: inputs_type: self:
    map (pypkg:
      let
        pname = normalizeName (get_pname pypkg);
      in
        if self ? "${pname}" && pypkg != self."${pname}" then
          trace "Updated inherited nixpkgs dep ${pname} from ${pypkg.version} to ${self."${pname}".version}"
          self."${pname}"
        else
          pypkg
    ) (oldAttrs."${inputs_type}" or []);
  override = pkg:
    if hasAttr "overridePythonAttrs" pkg then
        pkg.overridePythonAttrs
    else
        pkg.overrideAttrs;
  nameMap = {
    pytorch = "torch";
  };
  get_pname = pkg:
    let
      res = tryEval (
        if pkg ? src.pname then
          pkg.src.pname
        else if pkg ? pname then
          let pname = pkg.pname; in
            if nameMap ? "${pname}" then nameMap."${pname}" else pname
          else ""
      );
    in
      toString res.value;
  get_passthru = pypi_name: nix_name:
    # if pypi_name is in nixpkgs, we must pick it, otherwise risk infinite recursion.
    let
      python_pkgs = python.pkgs;
      pname = if hasAttr "${pypi_name}" python_pkgs then pypi_name else nix_name;
    in
      if hasAttr "${pname}" python_pkgs then
        let result = (tryEval
          (if isNull python_pkgs."${pname}" then
            {}
          else
            python_pkgs."${pname}".passthru));
        in
          if result.success then result.value else {}
      else {};
  tests_on_off = enabled: pySelf: pySuper:
    let
      mod = {
        doCheck = enabled;
        doInstallCheck = enabled;
      };
    in
    {
      buildPythonPackage = args: pySuper.buildPythonPackage ( args // {
        doCheck = enabled;
        doInstallCheck = enabled;
      } );
      buildPythonApplication = args: pySuper.buildPythonPackage ( args // {
        doCheck = enabled;
        doInstallCheck = enabled;
      } );
    };
  pname_passthru_override = pySelf: pySuper: {
    fetchPypi = args: (pySuper.fetchPypi args).overrideAttrs (oa: {
      passthru = { inherit (args) pname; };
    });
  };
  mergeOverrides = with pkgs.lib; foldl composeExtensions (self: super: {});
  merge_with_overr = enabled: overr:
    mergeOverrides [(tests_on_off enabled) pname_passthru_override overr];
  select_pkgs = ps: [
    ps."deeplabcut"
  ];
  patchelflibjpegHook = pkgs.makeSetupHook { name = "patchelf-hook-libjpeg"; } ./patchelf-libjpeg.sh;
  overrides = manylinux1: autoPatchelfHook: merge_with_overr false (python-self: python-super: let self = {
    "wxPython" = python-self.buildPythonPackage {
      pname = "wxPython";
      version = "4.1.1";
      src = ./wxPython-4.1.1-cp37-cp37m-linux_x86_64.whl ;
      format = "wheel";
      propagatedBuildInputs = with python-self; [ numpy pillow six ];
      buildInputs = [
        pkgs.stdenv.cc.cc.lib
        pkgs.gdk-pixbuf
        pkgs.fontconfig
        pkgs.gtk3
        pkgs.libpng
        pkgs.SDL2
        pkgs.webkitgtk
        pkgs.expat
        pkgs.gst_all_1.gstreamer
        pkgs.libjpeg_original
        pkgs.xorg.libXtst
        pkgs.makeWrapper
        pkgs.jbigkit
        pkgs.libGLU
      ];
      autoPatchelfIgnoreMissingDeps = true;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];# patchelflibjpegHook ];
    };
    "backcall" = python-self.buildPythonPackage {
      pname = "backcall";
      version = "0.2.0";
      src = fetchPypiWheel "backcall" "0.2.0" "backcall-0.2.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "backcall" "backcall") // { provider = "wheel"; };
    };
    "certifi" = python-self.buildPythonPackage {
      pname = "certifi";
      version = "2020.6.20";
      src = fetchPypiWheel "certifi" "2020.6.20" "certifi-2020.6.20-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "certifi" "certifi") // { provider = "wheel"; };
    };
    "chardet" = python-self.buildPythonPackage {
      pname = "chardet";
      version = "3.0.4";
      src = fetchPypiWheel "chardet" "3.0.4" "chardet-3.0.4-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "chardet" "chardet") // { provider = "wheel"; };
    };
    "click" = python-self.buildPythonPackage {
      pname = "click";
      version = "7.1.2";
      src = fetchPypiWheel "click" "7.1.2" "click-7.1.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "click" "click") // { provider = "wheel"; };
    };
    "cycler" = python-self.buildPythonPackage {
      pname = "cycler";
      version = "0.10.0";
      src = fetchPypiWheel "cycler" "0.10.0" "cycler-0.10.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "cycler" "cycler") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ six ];
    };
    "decorator" = python-self.buildPythonPackage {
      pname = "decorator";
      version = "4.4.2";
      src = fetchPypiWheel "decorator" "4.4.2" "decorator-4.4.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "decorator" "decorator") // { provider = "wheel"; };
    };
    "deeplabcut" = python-self.buildPythonPackage {
      pname = "deeplabcut";
      version = "2.1.7";
      src = fetchPypiWheel "deeplabcut" "2.1.7" "deeplabcut-2.1.7-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "deeplabcut" "deeplabcut") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ certifi chardet click easydict h5py imgaug intel-openmp ipython ipython-genutils matplotlib moviepy numpy opencv-python pandas patsy python-dateutil pyyaml requests python-self."ruamel.yaml" scikit-image scikit-learn scipy setuptools six statsmodels tables tensorpack tqdm wheel pkgs.python37Packages.wxPython_4_0 ];
    };
    "easydict" = override python-super.easydict ( oldAttrs: {
      pname = "easydict";
      version = "1.9";
      passthru = (get_passthru "easydict" "easydict") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "easydict" "1.9";
    });
    "h5py" = python-self.buildPythonPackage {
      pname = "h5py";
      version = "2.10.0";
      src = fetchPypiWheel "h5py" "2.10.0" "h5py-2.10.0-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "h5py" "h5py") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy six ];
    };
    "idna" = python-self.buildPythonPackage {
      pname = "idna";
      version = "2.10";
      src = fetchPypiWheel "idna" "2.10" "idna-2.10-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "idna" "idna") // { provider = "wheel"; };
    };
    "imageio" = python-self.buildPythonPackage {
      pname = "imageio";
      version = "2.9.0";
      src = fetchPypiWheel "imageio" "2.9.0" "imageio-2.9.0-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "imageio" "imageio") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ numpy pillow ];
    };
    "imgaug" = python-self.buildPythonPackage {
      pname = "imgaug";
      version = "0.4.0";
      src = fetchPypiWheel "imgaug" "0.4.0" "imgaug-0.4.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "imgaug" "imgaug") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ imageio matplotlib numpy opencv-python pillow scikit-image scipy shapely six ];
    };
    "intel-openmp" = python-self.buildPythonPackage {
      pname = "intel-openmp";
      version = "2020.0.133";
      src = fetchPypiWheel "intel-openmp" "2020.0.133" "intel_openmp-2020.0.133-py2.py3-none-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "intel-openmp" "intel-openmp") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "ipython" = python-self.buildPythonPackage {
      pname = "ipython";
      version = "7.18.1";
      src = fetchPypiWheel "ipython" "7.18.1" "ipython-7.18.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "ipython" "ipython") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ backcall decorator jedi pexpect pickleshare prompt-toolkit pygments setuptools traitlets ];
    };
    "ipython-genutils" = python-self.buildPythonPackage {
      pname = "ipython-genutils";
      version = "0.2.0";
      src = fetchPypiWheel "ipython-genutils" "0.2.0" "ipython_genutils-0.2.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "ipython-genutils" "ipython_genutils") // { provider = "wheel"; };
    };
    "jedi" = python-self.buildPythonPackage {
      pname = "jedi";
      version = "0.17.2";
      src = fetchPypiWheel "jedi" "0.17.2" "jedi-0.17.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "jedi" "jedi") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ parso ];
    };
    "joblib" = python-self.buildPythonPackage {
      pname = "joblib";
      version = "0.17.0";
      src = fetchPypiWheel "joblib" "0.17.0" "joblib-0.17.0-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "joblib" "joblib") // { provider = "wheel"; };
    };
    "kiwisolver" = python-self.buildPythonPackage {
      pname = "kiwisolver";
      version = "1.2.0";
      src = fetchPypiWheel "kiwisolver" "1.2.0" "kiwisolver-1.2.0-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "kiwisolver" "kiwisolver") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "matplotlib" = python-self.buildPythonPackage {
      pname = "matplotlib";
      version = "3.0.3";
      src = fetchPypiWheel "matplotlib" "3.0.3" "matplotlib-3.0.3-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "matplotlib" "matplotlib") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ cycler kiwisolver numpy pyparsing python-dateutil ];
    };
    "moviepy" = python-self.buildPythonPackage {
      pname = "moviepy";
      version = "0.2.3.1";
      src = fetchPypiWheel "moviepy" "0.2.3.1" "moviepy-0.2.3.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "moviepy" "moviepy") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ decorator imageio numpy tqdm ];
    };
    "msgpack" = python-self.buildPythonPackage {
      pname = "msgpack";
      version = "1.0.0";
      src = fetchPypiWheel "msgpack" "1.0.0" "msgpack-1.0.0-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "msgpack" "msgpack") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "msgpack-numpy" = python-self.buildPythonPackage {
      pname = "msgpack-numpy";
      version = "0.4.7.1";
      src = fetchPypiWheel "msgpack-numpy" "0.4.7.1" "msgpack_numpy-0.4.7.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "msgpack-numpy" "msgpack-numpy") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ msgpack numpy ];
    };
    "networkx" = python-self.buildPythonPackage {
      pname = "networkx";
      version = "2.5";
      src = fetchPypiWheel "networkx" "2.5" "networkx-2.5-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "networkx" "networkx") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ decorator ];
    };
    "numexpr" = python-self.buildPythonPackage {
      pname = "numexpr";
      version = "2.7.1";
      src = fetchPypiWheel "numexpr" "2.7.1" "numexpr-2.7.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "numexpr" "numexpr") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy ];
    };
    "numpy" = python-self.buildPythonPackage {
      pname = "numpy";
      version = "1.16.4";
      src = fetchPypiWheel "numpy" "1.16.4" "numpy-1.16.4-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "numpy" "numpy") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "opencv-python" = python-self.buildPythonPackage {
      pname = "opencv-python";
      version = "3.4.11.43";
      src = fetchPypiWheel "opencv-python" "3.4.11.43" "opencv_python-3.4.11.43-cp37-cp37m-manylinux2014_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "opencv-python" "opencv-python") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy ];
    };
    "pandas" = python-self.buildPythonPackage {
      pname = "pandas";
      version = "1.1.3";
      src = fetchPypiWheel "pandas" "1.1.3" "pandas-1.1.3-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pandas" "pandas") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy python-dateutil pytz ];
    };
    "parso" = python-self.buildPythonPackage {
      pname = "parso";
      version = "0.7.1";
      src = fetchPypiWheel "parso" "0.7.1" "parso-0.7.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "parso" "parso") // { provider = "wheel"; };
    };
    "patsy" = python-self.buildPythonPackage {
      pname = "patsy";
      version = "0.5.1";
      src = fetchPypiWheel "patsy" "0.5.1" "patsy-0.5.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "patsy" "patsy") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ numpy six ];
    };
    "pexpect" = python-self.buildPythonPackage {
      pname = "pexpect";
      version = "4.8.0";
      src = fetchPypiWheel "pexpect" "4.8.0" "pexpect-4.8.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pexpect" "pexpect") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ ptyprocess ];
    };
    "pickleshare" = python-self.buildPythonPackage {
      pname = "pickleshare";
      version = "0.7.5";
      src = fetchPypiWheel "pickleshare" "0.7.5" "pickleshare-0.7.5-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pickleshare" "pickleshare") // { provider = "wheel"; };
    };
    "pillow" = python-self.buildPythonPackage {
      pname = "pillow";
      version = "8.0.1";
      src = fetchPypiWheel "pillow" "8.0.1" "Pillow-8.0.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      doCheck = false;
      passthru = (get_passthru "pillow" "pillow") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "prompt-toolkit" = python-self.buildPythonPackage {
      pname = "prompt-toolkit";
      version = "3.0.8";
      src = fetchPypiWheel "prompt-toolkit" "3.0.8" "prompt_toolkit-3.0.8-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "prompt-toolkit" "prompt_toolkit") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ wcwidth ];
    };
    "psutil" = override python-super.psutil ( oldAttrs: {
      pname = "psutil";
      version = "5.7.2";
      passthru = (get_passthru "psutil" "psutil") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "psutil" "5.7.2";
    });
    "ptyprocess" = python-self.buildPythonPackage {
      pname = "ptyprocess";
      version = "0.6.0";
      src = fetchPypiWheel "ptyprocess" "0.6.0" "ptyprocess-0.6.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "ptyprocess" "ptyprocess") // { provider = "wheel"; };
    };
    "pygments" = python-self.buildPythonPackage {
      pname = "pygments";
      version = "2.7.1";
      src = fetchPypiWheel "pygments" "2.7.1" "Pygments-2.7.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pygments" "pygments") // { provider = "wheel"; };
    };
    "pyparsing" = python-self.buildPythonPackage {
      pname = "pyparsing";
      version = "2.4.7";
      src = fetchPypiWheel "pyparsing" "2.4.7" "pyparsing-2.4.7-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pyparsing" "pyparsing") // { provider = "wheel"; };
    };
    "python-dateutil" = python-self.buildPythonPackage {
      pname = "python-dateutil";
      version = "2.8.1";
      src = fetchPypiWheel "python-dateutil" "2.8.1" "python_dateutil-2.8.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "python-dateutil" "python-dateutil") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ six ];
    };
    "pytz" = python-self.buildPythonPackage {
      pname = "pytz";
      version = "2020.1";
      src = fetchPypiWheel "pytz" "2020.1" "pytz-2020.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pytz" "pytz") // { provider = "wheel"; };
    };
    "pywavelets" = python-self.buildPythonPackage {
      pname = "pywavelets";
      version = "1.1.1";
      src = fetchPypiWheel "pywavelets" "1.1.1" "PyWavelets-1.1.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pywavelets" "pywavelets") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy ];
    };
    "pyyaml" = override python-super.pyyaml ( oldAttrs: {
      pname = "pyyaml";
      version = "5.3.1";
      passthru = (get_passthru "pyyaml" "pyyaml") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "pyyaml" "5.3.1";
    });
    "pyzmq" = python-self.buildPythonPackage {
      pname = "pyzmq";
      version = "19.0.2";
      src = fetchPypiWheel "pyzmq" "19.0.2" "pyzmq-19.0.2-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pyzmq" "pyzmq") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "requests" = python-self.buildPythonPackage {
      pname = "requests";
      version = "2.24.0";
      src = fetchPypiWheel "requests" "2.24.0" "requests-2.24.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "requests" "requests") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ certifi chardet idna urllib3 ];
    };
    "ruamel.yaml" = python-self.buildPythonPackage {
      pname = "ruamel.yaml";
      version = "0.16.12";
      src = fetchPypiWheel "ruamel.yaml" "0.16.12" "ruamel.yaml-0.16.12-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "ruamel.yaml" "ruamel_yaml") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ python-self."ruamel.yaml.clib" ];
    };
    "ruamel.yaml.clib" = python-self.buildPythonPackage {
      pname = "ruamel.yaml.clib";
      version = "0.2.2";
      src = fetchPypiWheel "ruamel.yaml.clib" "0.2.2" "ruamel.yaml.clib-0.2.2-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "ruamel.yaml.clib" "ruamel_yaml_clib") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "scikit-image" = python-self.buildPythonPackage {
      pname = "scikit-image";
      version = "0.17.2";
      src = fetchPypiWheel "scikit-image" "0.17.2" "scikit_image-0.17.2-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "scikit-image" "scikitimage") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ imageio matplotlib networkx numpy pillow pywavelets scipy tifffile ];
    };
    "scikit-learn" = python-self.buildPythonPackage {
      pname = "scikit-learn";
      version = "0.23.2";
      src = fetchPypiWheel "scikit-learn" "0.23.2" "scikit_learn-0.23.2-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "scikit-learn" "scikitlearn") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ joblib numpy scipy threadpoolctl ];
    };
    "scipy" = python-self.buildPythonPackage {
      pname = "scipy";
      version = "1.5.3";
      src = fetchPypiWheel "scipy" "1.5.3" "scipy-1.5.3-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "scipy" "scipy") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy ];
    };
    "setuptools" = override python-super.setuptools ( oldAttrs: {
      pname = "setuptools";
      version = "47.3.1";
      passthru = (get_passthru "setuptools" "setuptools") // { provider = "nixpkgs"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
    });
    "shapely" = python-self.buildPythonPackage {
      pname = "shapely";
      version = "1.7.1";
      src = fetchPypiWheel "shapely" "1.7.1" "Shapely-1.7.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "shapely" "shapely") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "six" = python-self.buildPythonPackage {
      pname = "six";
      version = "1.15.0";
      src = fetchPypiWheel "six" "1.15.0" "six-1.15.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "six" "six") // { provider = "wheel"; };
    };
    "statsmodels" = python-self.buildPythonPackage {
      pname = "statsmodels";
      version = "0.12.0";
      src = fetchPypiWheel "statsmodels" "0.12.0" "statsmodels-0.12.0-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "statsmodels" "statsmodels") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy pandas patsy scipy ];
    };
    "tables" = python-self.buildPythonPackage {
      pname = "tables";
      version = "3.6.1";
      src = fetchPypiWheel "tables" "3.6.1" "tables-3.6.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tables" "tables") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numexpr numpy ];
    };
    "tabulate" = python-self.buildPythonPackage {
      pname = "tabulate";
      version = "0.8.7";
      src = fetchPypiWheel "tabulate" "0.8.7" "tabulate-0.8.7-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tabulate" "tabulate") // { provider = "wheel"; };
    };
    "tensorpack" = python-self.buildPythonPackage {
      pname = "tensorpack";
      version = "0.10.1";
      src = fetchPypiWheel "tensorpack" "0.10.1" "tensorpack-0.10.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tensorpack" "tensorpack") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ msgpack msgpack-numpy numpy psutil pyzmq six tabulate termcolor tqdm ];
    };
    "termcolor" = override python-super.termcolor ( oldAttrs: {
      pname = "termcolor";
      version = "1.1.0";
      passthru = (get_passthru "termcolor" "termcolor") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "termcolor" "1.1.0";
    });
    "threadpoolctl" = python-self.buildPythonPackage {
      pname = "threadpoolctl";
      version = "2.1.0";
      src = fetchPypiWheel "threadpoolctl" "2.1.0" "threadpoolctl-2.1.0-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "threadpoolctl" "threadpoolctl") // { provider = "wheel"; };
    };
    "tifffile" = python-self.buildPythonPackage {
      pname = "tifffile";
      version = "2020.10.1";
      src = fetchPypiWheel "tifffile" "2020.10.1" "tifffile-2020.10.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tifffile" "tifffile") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ numpy ];
    };
    "tqdm" = python-self.buildPythonPackage {
      pname = "tqdm";
      version = "4.50.2";
      src = fetchPypiWheel "tqdm" "4.50.2" "tqdm-4.50.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tqdm" "tqdm") // { provider = "wheel"; };
    };
    "traitlets" = python-self.buildPythonPackage {
      pname = "traitlets";
      version = "5.0.5";
      src = fetchPypiWheel "traitlets" "5.0.5" "traitlets-5.0.5-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "traitlets" "traitlets") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ ipython-genutils ];
    };
    "urllib3" = python-self.buildPythonPackage {
      pname = "urllib3";
      version = "1.25.11";
      src = fetchPypiWheel "urllib3" "1.25.11" "urllib3-1.25.11-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "urllib3" "urllib3") // { provider = "wheel"; };
    };
    "wcwidth" = python-self.buildPythonPackage {
      pname = "wcwidth";
      version = "0.2.5";
      src = fetchPypiWheel "wcwidth" "0.2.5" "wcwidth-0.2.5-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "wcwidth" "wcwidth") // { provider = "wheel"; };
    };
    "wheel" = override python-super.wheel ( oldAttrs: {
      pname = "wheel";
      version = "0.34.2";
      passthru = (get_passthru "wheel" "wheel") // { provider = "nixpkgs"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
    });
  }; in self);
in
{ inherit overrides select_pkgs; }
