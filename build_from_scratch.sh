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
module load python/3.7-anaconda-2019.07
source /usr/common/software/python/3.7-anaconda-2019.07/etc/profile.d/conda.sh
conda activate $PWD/psana2_py37
EOF

source env.sh

# Clean up any previous installs
rm -rf lcls2
conda env list | grep psana2_py37
if [ $? -eq 0 ]
then
  source /usr/common/software/python/3.7-anaconda-2019.07/etc/profile.d/conda.sh
  conda activate base
  conda env remove -p $PWD/psana2_py37 --all

fi

# Remove conda installation
rm -rf psana2_py37

# Create a new conda env from Nersc base
conda env create -f env_create.yaml -p ./psana2_py37
conda config --append envs_dirs $PWD/psana2_py37
source /usr/common/software/python/3.7-anaconda-2019.07/etc/profile.d/conda.sh
conda activate $PWD/psana2_py37
conda install ipykernel

# Build psana
git clone https://github.com/slac-lcls/lcls2.git
pushd $PSANA_PREFIX
    module swap PrgEnv-intel PrgEnv-gnu
    CC=/opt/gcc/7.3.0/bin/gcc CXX=/opt/gcc/7.3.0/bin/g++ ./build_all.sh -d
popd

# Remove mpi4py from psana conda env and rebuild mpi4py with NERSC cray mpich
conda uninstall -y mpi4py
wget https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-3.0.0.tar.gz
tar zxvf mpi4py-3.0.0.tar.gz
module unload craype-hugepages2M
pushd mpi4py-3.0.0
    python setup.py build --mpicc="$(which cc) -shared"
    python setup.py install
popd

conda activate $PWD/psana2_py37
pip install git+https://github.com/muammar/slurm-magic.git
pip install dask distributed sklearn multipledispatch numba
conda install ipykernel
conda install -c plotly plotly
conda install -c conda-forge matplotlib ipympl
conda install -c pyviz holoviews bokeh
jupyter labextension install @pyviz/jupyterlab_pyviz

echo
echo "Done. Please run 'source env.sh' to use this build."
