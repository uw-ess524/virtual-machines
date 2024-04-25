FROM firedrakeproject/firedrake-vanilla:2024-04
MAINTAINER shapero@uw.edu

RUN sudo apt-get update && sudo apt-get install -yq \
    patchelf

# Hack to activate the firedrake virtual environment.
ENV PATH=/home/firedrake/firedrake/bin:$PATH

# Another hack because OpenMP and OpenBLAS are silly.
ENV OMP_NUM_THREADS=1

# Install some dependencies and create a Jupyter kernel for the venv
RUN python -m pip install ipykernel jupyter jupyterlab
RUN python -m ipykernel install --user --name=firedrake
