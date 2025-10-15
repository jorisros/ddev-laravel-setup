# ddev-laravel-setup
A project to store the script for DDEV project setup

## Install script locally on OSX

### Run this command only on linux
```
mkdir -p ~/.local/bin
```
Then add it to bash file
```
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```
And reload the variables of the terminal
```
source ~/.bashrc
```

### This works on Linx and OSX


```bash
curl -fsSL https://raw.githubusercontent.com/jorisros/ddev-laravel-setup/main/setup-laravel.sh -o ~/.local/bin/ddev-laravel && chmod +x ~/.local/bin/ddev-laravel
```

Then can you run the creation of new projects script
```bash
ddev-laravel project-name
```

## Development
```bash
git clone git@github.com:jorisros/ddev-laravel-setup.git
```
```bash
cd ddev-laravel-setup
```
```bash
chmod +x setup-laravel.sh
```
```bash
./setpu-laravel.sh
```
