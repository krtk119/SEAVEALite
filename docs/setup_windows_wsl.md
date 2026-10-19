# Windows Setup Guide using WSL2

This guide explains how to set up the SEAVEA workflow notebook on Windows using WSL2 Ubuntu.

Native Windows PowerShell or Command Prompt is not recommended for the full FabSim3/FLEE/FabFlee workflow because the workflow uses:

- Unix-style paths
- Bash commands
- SSH localhost execution
- Python virtual environments
- FabSim3 command-line tooling

Use WSL2 Ubuntu instead.

## 1. Install WSL2 Ubuntu

Open PowerShell as Administrator and run:

```powershell
wsl --install -d Ubuntu
```

Restart the computer if Windows asks.

Open Ubuntu from the Start Menu and create your Linux username and password.

## 2. Update Ubuntu

Inside the Ubuntu terminal:

```bash
sudo apt update
```

Optionally, `sudo apt upgrade -y` updates every installed package. The tutorial does not need it, and on an existing WSL install it can take a long time.

Install required packages:

```bash
sudo apt install -y git python3 python3-venv python3-pip openssh-client openssh-server build-essential software-properties-common
```

The tutorial needs Python 3.10, 3.11 or 3.12, because the pinned `numpy` and `scipy` versions have no ready-made packages for newer Python (Ubuntu 26.04 ships Python 3.14). Install Python 3.11 alongside the system Python:

```bash
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv
python3.11 --version
```

Start SSH:

```bash
sudo service ssh start
```

Test localhost SSH:

```bash
ssh localhost "echo SSH works"
```

If SSH asks whether to continue connecting, type:

```text
yes
```

## 3. Clone the SEAVEA-notebooks repository

```bash
mkdir -p ~/seavea
cd ~/seavea
git clone https://github.com/cspgdds/SEAVEA-notebooks.git
cd SEAVEA-notebooks
```

## 4. Create the notebook environment

```bash
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip wheel "setuptools<70"
pip install -r requirements.txt
python -m ipykernel install --user --name seavea-notebooks --display-name "SEAVEA Notebooks"
```

## 5. Clone and configure FabSim3

```bash
cd ~/seavea
git clone https://github.com/djgroen/FabSim3.git
cd FabSim3
python3.11 -m venv VirtualEnv
source VirtualEnv/bin/activate
python configure_fabsim.py
ln -sf ~/seavea/FabSim3/fabsim/bin/fabsim ~/seavea/FabSim3/VirtualEnv/bin/fabsim
```

Check FabSim3:

```bash
which fabsim
fabsim localhost -h
```

## 6. Clone and install FLEE

```bash
cd ~/seavea
git clone https://github.com/djgroen/flee.git
cd flee
source ~/seavea/FabSim3/VirtualEnv/bin/activate
pip install -e .
```

Check FLEE:

```bash
python - <<'PY'
import flee
print("FLEE imported successfully")
PY
```

## 7. Install FabFlee plugin

```bash
cd ~/seavea/FabSim3
source VirtualEnv/bin/activate
fabsim localhost install_plugin:FabFlee
```

Install required Python packages:

```bash
pip install "numpy==1.26.4" easyvvuq chaospy plotly "setuptools<70" wheel folium ipython
```

Check FabFlee tasks:

```bash
fabsim localhost -l tasks | grep -i flee
```

## 8. Configure FabSim3 machine settings

Copy the example configuration:

```bash
cp ~/seavea/SEAVEA-notebooks/examples/machines_user.example.yml \
   ~/seavea/FabSim3/fabsim/deploy/machines_user.yml
```

Edit it:

```bash
nano ~/seavea/FabSim3/fabsim/deploy/machines_user.yml
```

Example WSL configuration:

```yaml
default:
  local_results: /home/YOUR_WSL_USERNAME/FabSim/results
  local_configs: /home/YOUR_WSL_USERNAME/FabSim/config_files
  username: YOUR_WSL_USERNAME

localhost:
  username: YOUR_WSL_USERNAME
  cores: 1
  corespernode: 1
  cpuspertask: 1
  taskspernode: 1
  virtual_env_path: /home/YOUR_WSL_USERNAME/seavea/FabSim3/VirtualEnv
  python3_command: /home/YOUR_WSL_USERNAME/seavea/FabSim3/VirtualEnv/bin/python
  flee_location: /home/YOUR_WSL_USERNAME/seavea/flee
  enable_template_cache: false
  template_cache_size: 2000
```

Find your WSL username:

```bash
whoami
```

Replace `YOUR_WSL_USERNAME` with the result.

## 9. Run the Mali2012 baseline

```bash
cd ~/seavea/FabSim3
source VirtualEnv/bin/activate
fabsim localhost sflee:mali2012,simulation_period=50
fabsim localhost fetch_results
```

Check output:

```bash
find ~/FabSim/results -path "*mali*" -name "out.csv"
```

The output CSV should contain a column called:

```text
Total error
```

## 10. Run EasyVVUQ sensitivity analysis

```bash
cd ~/seavea/FabSim3
source VirtualEnv/bin/activate

fabsim localhost flee_init_SA:mali2012
fabsim localhost fetch_results
```

Check generated runs:

```bash
find ~/FabSim/results/mali2012_localhost_1_SA_SCSampler/RUNS -maxdepth 2 -name "out.csv" | sort
```

Check `Total error` exists in every run:

```bash
for f in ~/FabSim/results/mali2012_localhost_1_SA_SCSampler/RUNS/run_*/out.csv; do
  echo "Checking $f"
  head -1 "$f" | grep "Total error" || echo "MISSING Total error in $f"
done
```

Analyse the sensitivity-analysis results:

```bash
fabsim localhost flee_analyse_SA:mali2012
```

Expected analysis outputs include:

```text
collation_result.csv
sobols.yml
plot_sobols_first[Total error].png
plot_statistical_moments[Total error].png
raw[Total error].png
```

## Opening files in Windows Explorer

From WSL, you can open the current folder in Windows Explorer:

```bash
explorer.exe .
```

You can open the FabFlee sensitivity-analysis output folder using:

```bash
explorer.exe "$(wslpath -w ~/seavea/FabSim3/plugins/FabFlee/SA/flee_SA_SCSampler_mali2012/)"
```

## Troubleshooting

If `python3.11 -m venv` fails with an `ensurepip` error, run:

```bash
sudo apt update
sudo apt install -y python3.11-venv
```

If SSH localhost fails:

```bash
sudo service ssh start
ssh localhost "echo SSH works"
```

If SSH says host identification has changed:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R localhost
ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:22'
ssh localhost "echo SSH works"
```

If `fabsim` is not found, activate the FabSim3 environment again:

```bash
cd ~/seavea/FabSim3
source VirtualEnv/bin/activate
```
