#!/bin/bash

# Setup environment
cat > env.sh <<EOF
# variables needed to run psana2
export PSANA_PREFIX=$PWD/lcls2
export PATH=\$PSANA_PREFIX/install/bin:${PATH}
export PYTHONPATH=\$PSANA_PREFIX/install/lib/python3.7/site-packages
# for procmgr
export TESTRELDIR=\$PSANA_PREFIX/install

# variables needed for conda
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate $PWD/psana2_py37
EOF

source env.sh

# Clean up any previous installs
rm -rf lcls2
conda env list | grep psana2_py37
if [ $? -eq 0 ]
then
  source $HOME/miniconda3/etc/profile.d/conda.sh
  conda activate base
  conda env remove -p $PWD/psana2_py37 --all

fi

# Remove conda installation
rm -rf psana2_py37

# Create a new conda env
conda env create -f env_create.yaml -p ./psana2_py37
conda config --append envs_dirs $PWD/psana2_py37
source $HOME/miniconda3/etc/profile.d/conda.sh
conda activate $PWD/psana2_py37
conda install ipykernel

# Build psana
git clone https://github.com/slac-lcls/lcls2.git
source scl_source enable devtoolset-7

pushd $PSANA_PREFIX
    ./build_all.sh -d
popd

conda activate $PWD/psana2_py37
pip install git+https://github.com/muammar/slurm-magic.git
pip install dask distributed sklearn multipledispatch numba
conda install ipykernel
conda install -c plotly plotly

echo
echo "Done. Please run 'source env.sh' to use this build."
