#!/bin/bash

# install command
# curl https://raw.githubusercontent.com/Royce-Geospatial-Consultants/h2ogpt_rg/wor-508_build-h2ogpt_rg-in-codespace/royce_ubuntu-install_script_v1-0-0-a.sh | bash

setup_environment() {
    sudo localectl set-keymap us
    sudo localectl set-x11-keymap us
}

# Call the function to execute it
setup_environment

# Update and install git
sudo apt-get update -y
if ! command -v git &> /dev/null; then
  sudo apt-get install git -y
else
  echo "Git is already installed."
fi

# Print git version
git --version

# Install Miniconda
install_miniconda() {
  # Download the Miniconda installer using curl
  if curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; then
    # Make the downloaded script executable
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    
    # Run the Miniconda installer in silent mode
    if echo "yes" | ./Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3; then
      echo "Miniconda installed successfully."
    else
      echo "Miniconda installation failed."
    fi
  else
    echo "Failed to download Miniconda installer."
  fi
}


# Verify the installation by checking if 'conda' command is available
source $HOME/miniconda3/etc/profile.d/conda.sh
if conda --version >/dev/null 2>&1; then
  echo "Miniconda installed successfully."
else
  echo "Miniconda installation failed. Please manually install or consult the documentation."
  exit 1
fi

# Initialize conda for shell interaction
conda init bash

if [ -n "$BASH_VERSION" ]; then
    echo "export PATH=\"$HOME/miniconda3/bin:\$PATH\"" >> ~/.bashrc
    source ~/.bashrc
    echo "bashrc file successfully initialized for conda environment"
elif [ -n "$ZSH_VERSION" ]; then
    echo "export PATH=\"$HOME/miniconda3/bin:\$PATH\"" >> ~/.zshrc
    source ~/.zshrc
    echo "zshrc file successfully initialized for conda environment"
else
    echo "Shell not supported for automatic PATH update. Please manually update your PATH."
fi

# Clone repository if not already cloned
if [ ! -d "h2ogpt_rg" ]; then
  git clone https://github.com/Royce-Geospatial-Consultants/h2ogpt_rg.git
else
  echo "Repository already cloned."
fi
cd h2ogpt_rg

# Create conda environment if not already created
if ! conda env list | grep -q 'h2ogpt_rg'; then
  conda create --name h2ogpt_rg python=3.10 -y
else
  echo "Conda environment h2ogpt_rg already exists."
fi

# Activate the base environment to update Conda itself
source activate base || conda activate base
# Update conda to the latest version
conda update -n base -c defaults conda -y

# Activate the specific environment
source activate h2ogpt_rg || conda activate h2ogpt_rg

# Print Python version
python --version

# Print a hello message
python -c "import os, sys ; print('hello world - conda successfully installed and python is working')"

# Install other dependencies
conda install cudatoolkit-dev -c conda-forge -y
export CUDA_HOME=$CONDA_PREFIX
pip uninstall -y pandoc pypandoc pypandoc-binary
pip install -r requirements.txt --extra-index https://download.pytorch.org/whl/cu117

# Additional installation
pip install -r reqs_optional/requirements_optional_langchain.txt
pip install -r reqs_optional/requirements_optional_gpt4all.txt
pip install -r reqs_optional/requirements_optional_langchain.gpllike.txt
pip install -r reqs_optional/requirements_optional_langchain.urls.txt
sudo apt-get install -y libmagic-dev poppler-utils tesseract-ocr libtesseract-dev libreoffice
python -m nltk.downloader all

# More pip installations
pip uninstall -y auto-gptq
pip install https://s3.amazonaws.com/artifacts.h2o.ai/deps/h2ogpt/auto_gptq-0.3.0-cp310-cp310-linux_x86_64.whl --use-deprecated=legacy-resolver
pip uninstall -y exllama
pip install https://github.com/jllllll/exllama/releases/download/0.0.8/exllama-0.0.8+cu118-cp310-cp310-linux_x86_64.whl --no-cache-dir

# Modify Python package
sp=`python -c 'import site; print(site.getsitepackages()[0])'`
sed -i 's/posthog\.capture/return\n            posthog.capture/' $sp/chromadb/telemetry/posthog.py

# GPU handling and further pip installations
pip uninstall -y llama-cpp-python
pip install https://github.com/jllllll/llama-cpp-python-cuBLAS-wheels/releases/download/textgen-webui/llama_cpp_python_cuda-0.1.73+cu117-cp310-cp310-linux_x86_64.whl

# Test CUDA availability
CUDA_AVAILABLE=$(python -c "import torch; print(torch.cuda.is_available())")

if [ "$CUDA_AVAILABLE" == "False" ]; then
  echo "CUDA is not available. Please go back to troubleshoot the install or the settings in the VM to ensure CUDA is available."
  exit 1
fi

# Print instructions for the first session
echo "UI using GPU with at least 24GB with streaming:"
echo "python generate.py --base_model=h2oai/h2ogpt-oasst1-512-12b --load_8bit=True --score_model=None --langchain_mode='UserData' --user_path=user_path"
