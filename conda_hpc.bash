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
(ai1008) [ ]$ conda install -y kaleido imageio
(ai1008) [ ]$ plotly_get_chrome
#The Chrome executable is now located at: /hpctmp/e1554287/conda/envs/ai1008/lib/python3.13/site-packages/choreographer/cli/browser_exe/chrome-linux64/chrome

# Make and register a named kernel (lives in $HOME; survives purges of $WORK and $SCRATCH; Jupyter sees this env by name)
python -m ipykernel install --user --name ai1008 --display-name "ai1008 (Atlas)"
#    Installed kernelspec ai1008 in /home/svu/e1554287/.local/share/jupyter/kernels/ai1008

#Data & env management (backup for reproducibility in case of purge)
conda env export --from-history > $HOME/projects/quant-reasoning/environment.yml

#make startup easy - we cd to /pbs/logs so running the JOB from the pbs/logs directory for logs etc is easier
cat > samstartup.sh << 'EOF'
#    > source /app1/ebenv
#    > module avail /app1/ebapps/arches/flat-avx2/modules/lang/Anaconda3
#    > module load Anaconda3/2023.09-0 && module list
#    > source "$(conda info --base)/etc/profile.d/conda.sh"
#    > conda activate ai1008
#    > cd $HOME/pbs/logs
#    > vim $HOME/pbs/sam_jlab_cpu.pbs
#    > EOF
EOF
source samstartup.sh

#some unix setups
vim ~/.vimrc
colorscheme desert

vim ~/.bashrc
# User specific aliases and functions
alias ls='ls --color=auto'
export PS1="\[\033[1;32m\]\u@\h:\[\033[1;34m\]\w\[\033[0m\]$ "
alias ll='ls -lhF'
alias gst='git status'
#some useful flags for ls
#    -l	Long format: shows permissions, owner, group, size, date, and filename
#    -a	All files: includes hidden files (those starting with .)
#    -r	Reverse order: reverses the sorting order
#    -t	Sort by time: sorts by last modification time (newest first, unless reversed)
#    -h	Human-readable: shows sizes as 1K, 234M, etc.
#    -F	Classify: adds / for directories, * for executables, @ for symlinks, etc.

#git and sshkey setup
ssh-keygen -t ed25519 -C "s.soni87@yahoo.com"
#  Enter passphrase:

eval "$(ssh-agent -s)"
#  Agent pid 133714

ssh-add ~/.ssh/id_ed25519
#  Enter passphrase for /home/svu/e1554287/.ssh/id_ed25519:
#  Identity added: /home/svu/e1554287/.ssh/id_ed25519 s.soni87@yahoo.com

eval "$(ssh-agent -s)"
#  Agent pid 133775

chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
vim ~/.ssh/config
#Add the following"
#  Host github.com
#    HostName ssh.github.com
#    Port 443
#    User git
#    IdentityFile ~/.ssh/id_ed25519
#    IdentitiesOnly yes
#    ServerAliveInterval 60
#    ServerAliveCountMax 3
#    StrictHostKeyChecking yes
#    UserKnownHostsFile ~/.ssh/known_hosts

ssh -T git@github.com
#  Warning: Permanently added '[[ssh.github.com](http://ssh.github.com/)]:443,[20.205.243.160]:443' (ECDSA) to the list of known hosts.
#  Enter passphrase for key '/home/.ssh/id_ed25519':
#  Hi samarthsoni17! You've successfully authenticated, but GitHub does not provide shell access.

#check updated list of known hosts:
cat ~/.ssh/known_hosts

cd $HOME/projects
git clone git@github.com:samarthsoni17/ideal-ML-train.git

git config --global user.name "Samarth Soni"
git config --global user.email "s.soni87@yahoo.com"
git config --global push.default simple
git config --global color.ui auto
#to go beyond git default colour scheme:
git config --global color.status true
# OPTIONAL Set custom colors for status output:
git config --global color.status.added "green bold"
git config --global color.status.changed "yellow bold"
git config --global color.status.untracked "red bold"
git config --global color.diff.meta "magenta bold"
git config --global color.branch.current "yellow reverse"
#to see current color settings:
git config --get-regexp color
