# Common environment project setup



## 1. Setting up WSL2 in IDE:

To setup correct WSL2 subsystem for IDE:

```bash
wsl --install
wsl --list --online # list of accesible distributions
wsl --install -d Debian 
```

For current projects, by default `Debian` will be used distro.

## 2. Updating IDE plug-ins:

For current setup stated below plug-in's are needed:
- WSL
- DevContainers

## 3. Updating system / bash utils:

For Debian useful packages:

```bash
sudo apt-get install neovim
```

## 4. Setting up git for `Debian` / `Linux`

For setting up git for the subsystem get:

```bash
sudo apt-get update
sudo apt-get install git-all

git --version   # check install
```

For correct git credencials and configuration, generate SSH keys by:

```bash
ssh-keygen -t ed25519 -C "changetheemail@email.com"

# set up passphrase and location
# get the public key and set up on github.com
```

There may be need for setting up, git config:

```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

5. Setting up `Debian` SSH agent autostart: 

To "autostart" SSH agent in `Debian` add following lines to your `.bashrc`:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/<id_key_placeholder> 2>/dev/null
fi
```

Where `<id_key_placeholder>` is your specific key load e.g. for git SSH connection.

## 6. Install and setup Docker:

Install Docker from official website and log in to your proper account.

Under `Settings/WSL Integration` enable integration with your distro.

The Docker daemon binds to a Unix socket, not a TCP port. By default it's the root user that owns the Unix socket, and other users can only access it using sudo. The Docker daemon always runs as the root user.

To create proper membership for docker and evaluate:

```bash
sudo groupadd docker
sudo usermod -aG docker $USER

# restart or activate through
newgrp docker
docker run hello-world
```

## 7. `.devcontainers`

New environment is setup on the `Debian` distribution through `.devcontainers` to isolate tools from the rest of the system. For more information about configuration you can reach out to: [VSCode .devcontainers](https://code.visualstudio.com/docs/devcontainers/create-dev-container) or to proper `.devcontainer` directory in this repository.