ssh <nusid>@<node>.nus.edu.sg
#$SCRATCH, $WORK, $HOME are various directories on the HPC system of which only $HOME survives 60-day housekeeping purges but also has a low 20GB capacity only

# Project scaffold (you already created this, keep as-is)
mkdir -p /$WORK/$USER/conda/envs /$WORK/$USER/data /$WORK/$USER/runs
mkdir -p /$SCRATCH/$USER/conda/pkgs /$SCRATCH/$USER/cache

# .condarc to keep envs/caches off $HOME
cat > $HOME/.condarc << 'EOF'
envs_dirs:
  - /$WORK/$USER/conda/envs
pkgs_dirs:
  - /$SCRATCH/$USER/conda/pkgs
EOF

# load the "ebenv" software environment, see https://bobcat.nus.edu.sg/hpc/support/ebenv for more information.
source /app1/ebenv

# load the required module to memory
module avail /app1/ebapps/arches/flat-avx2/modules/lang/Anaconda3
# load the Anaconda toolchain first
module load Anaconda3/2023.09-0 && module list
# load Conda's shell hook for this shell
source "$(conda info --base)/etc/profile.d/conda.sh"

# confirm conda and python versions
conda --version
python --version
which conda
which python
which pip
#/app1/ebapps/arches/flat-avx2/software/Anaconda3/2023.09-0/bin/pip
ls -larth $HOME
cat $HOME/.condarc

# See if conda is picking up config files
conda config --show-sources
#    ==> /home/svu/e1554287/.condarc <==
#    envs_dirs:
#      - /hpctmp/$USER/conda/envs
#    pkgs_dirs:
#      - /scratch2/$USER/conda/pkgs
#
#    ==> cmd_line <==
#    debug: False
#    json: False

# check the effective values of above settings
conda config --show | egrep '^(envs_dirs|pkgs_dirs)'
conda info | egrep 'envs directories|package cache'
#    package cache : /scratch2/e1554287/conda/pkgs
#    envs directories : /hpctmp/e1554287/conda/envs

# list all envs
conda info --envs
#     conda environments:
#
#    base                     /app1/ebapps/arches/flat-avx2/software/Anaconda3/2023.09-0
#    ai1008                   /hpctmp/e1554287/conda/envs/ai1008

# since pointing is correct, can create using name
conda create -n ai1008
conda activate ai1008
# in PBS job scripts, use explicit paths
conda create -y -p /hpctmp/$USER/conda/envs/ai1008
conda activate /$WORK/$USER/conda/envs/ai1008

# Prefer conda-forge + strict priority for consistent solves
(ai1008) [ ]$ conda config --add channels conda-forge
(ai1008) [ ]$ conda config --set channel_priority strict
#-y = “yes to all prompts” (helpful for non-interactive environments like HPC)
(ai1008) [ ]$ conda install -y jupyterlab ipython ipykernel numpy pandas scipy scikit-learn matplotlib tqdm ipywidgets pyarrow plotly

# Make and register a named kernel (lives in $HOME; survives purges of $WORK and $SCRATCH; Jupyter sees this env by name)
python -m ipykernel install --user --name ai1008 --display-name "ai1008 (Atlas)"
#    Installed kernelspec ai1008 in /home/svu/e1554287/.local/share/jupyter/kernels/ai1008

#Data & env management (backup for reproducibility in case of purge)
conda env export --from-history > $HOME/projects/quant-reasoning/environment.yml