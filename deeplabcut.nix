{ pkgs }:

with pkgs;
python37Packages.buildPythonPackage rec {
    pname = "deeplabcut";
    version = "2.2.0.1";

    src = fetchFromGitHub {
        owner = "DeepLabCut";
        repo = "DeepLabCut";
        rev = "2472d40a4b1a96130984d9f1bff070f15f5a92a9";
        sha256 = "0rr35lc41hgd6y7wvd7kx3qmfvsrkxis85mnx48dr6fx7m6iqnqq";
    };

    propagatedBuildInputs = with python37Packages; [ ipython filterpy ruamel_yaml imgaug numba matplotlib networkx numpy  ];

    meta = with lib; {
        homepage = "https://github.com/DeepLabCut/DeepLabCut/";
        description = "Official implementation of DeepLabCut: Markerless pose estimation of user-defined features with deep learning for all animals incl. humans.";
        license = licenses.gpl3Only;
        maintainers = with maintainers; [ Amathis ];
    };
}