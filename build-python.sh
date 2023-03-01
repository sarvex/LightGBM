#!/bin/sh

set -e -u -o pipefail

# Default values of arguments
BUILD_SDIST=""
BUILD_WHEEL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --sdist*)
      BUILD_SDIST='--sdist'
      ;;
    --wheel*)
      BUILD_WHEEL='--wheel'
      ;;
    *)
      echo "invalid argument '${1}'"
      exit -1
      ;;
  esac
  shift
done

DIST_DIR="${PWD}/dist"

pip install --prefer-binary build
pip uninstall -y lightgbm

rm -rf \
    ./lightgbm-python \
    ./lib_lightgbm.so \
    ./lightgbm \
    ./python-package/build \
    ./python-package/build_cpp \
    ./python-package/compile \
    ./python-package/dist \
    ./python-package/lightgbm.egg-info

cp -R ./python-package ./lightgbm-python
cp -R ./cmake ./lightgbm-python/
cp CMakeLists.txt ./lightgbm-python/
cp -R ./include ./lightgbm-python/
cp LICENSE ./lightgbm-python/
cp -R ./src ./lightgbm-python/
cp -R ./swig ./lightgbm-python/
cp VERSION.txt ./lightgbm-python/
cp -R ./windows ./lightgbm-python/

# include only specific files from external_libs, to keep the package
# small and avoid redistributing code with licenses incompatible with
# LightGBM's license
mkdir -p ./lightgbm-python/external_libs/fast_double_parser/include/
cp \
    external_libs/fast_double_parser/include/fast_double_parser.h \
    ./lightgbm-python/external_libs/fast_double_parser/include/

mkdir -p ./lightgbm-python/external_libs/fmt/include/fmt
cp \
    external_libs/fmt/include/fmt/*.h \
    ./lightgbm-python/external_libs/fmt/include/fmt/

mkdir -p ./lightgbm-python/external_libs/eigen/Eigen

modules="Cholesky Core Dense Eigenvalues Geometry Householder Jacobi LU QR SVD"
for eigen_module in ${modules}; do
    cp \
        external_libs/eigen/Eigen/${eigen_module} \
        ./lightgbm-python/external_libs/eigen/Eigen/${eigen_module}
    if [ ${eigen_module} != "Dense" ]; then
        mkdir -p ./lightgbm-python/external_libs/eigen/Eigen/src/${eigen_module}/
        cp \
            -R \
            external_libs/eigen/Eigen/src/${eigen_module}/* \
            ./lightgbm-python/external_libs/eigen/Eigen/src/${eigen_module}/
    fi
done

mkdir -p ./lightgbm-python/external_libs/eigen/Eigen/misc
cp \
    -R \
    external_libs/eigen/Eigen/src/misc \
    ./lightgbm-python/external_libs/eigen/Eigen/src/misc/

mkdir -p ./lightgbm-python/external_libs/eigen/Eigen/plugins
cp \
    -R \
    external_libs/eigen/Eigen/src/plugins \
    ./lightgbm-python/external_libs/eigen/Eigen/src/plugins/

mkdir -p ./lightgbm-python/external_libs/compute
cp \
    -R \
    external_libs/compute/cmake \
    ./lightgbm-python/external_libs/cmake/
cp \
    -R \
    external_libs/compute/include \
    ./lightgbm-python/external_libs/include/
cp \
    -R \
    external_libs/compute/meta \
    ./lightgbm-python/external_libs/meta/

pushd ./lightgbm-python
    python -m build \
        ${BUILD_SDIST} \
        ${BUILD_WHEEL} \
        --outdir "${DIST_DIR}" \
        .
popd