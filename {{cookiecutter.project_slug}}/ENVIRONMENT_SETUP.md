# Common environment project setup

## 1. Setting up WSL2

To set up the correct WSL2 subsystem for your IDE:

```bash
wsl --install
wsl --list --online   # list of available distributions
wsl --install -d Debian
```

For current projects, `Debian` is used as the default distro.

> **Tip:** Run `wsl --update` periodically to stay on the latest WSL2 kernel — older kernels can cause subtle networking and file-watcher issues inside dev containers.

> **Tip:** Keep project files inside the Linux filesystem (e.g. `~/projects/...`), not under `/mnt/c/...`. Cross-filesystem access from WSL2 to Windows drives is significantly slower and will make `uv sync`, git operations, and file watchers noticeably sluggish.

## 2. Updating IDE plug-ins

For the setup described below, the following plug-ins are needed:
- WSL
- Dev Containers

## 3. Updating system / bash utils

Useful packages for Debian:

```bash
sudo apt-get update
sudo apt-get install neovim
```

## 4. Setting up git for `Debian` / `Linux`

Install git for the subsystem:

```bash
sudo apt-get update
sudo apt-get install git-all

git --version   # check install
```

For git credentials and configuration, generate SSH keys:

```bash
ssh-keygen -t ed25519 -C "changetheemail@email.com"

# set a passphrase and confirm the save location
# then add the public key (~/.ssh/id_ed25519.pub) to github.com
```

Set your git identity:

```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

> **Tip:** Verify SSH access to GitHub works end-to-end before relying on it: `ssh -T git@github.com`.

## 5. Setting up SSH agent autostart on `Debian`

To autostart the SSH agent in `Debian`, add the following to your `.bashrc`:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/<id_key_placeholder> 2>/dev/null
fi
```

Where `<id_key_placeholder>` is the specific key to load, e.g. for git SSH connections.

> **Tip:** Confirm the agent picked up your key with `ssh-add -l`. If you're working inside this repo's `.devcontainer`, note that `SSH_AUTH_SOCK` is already forwarded in via the `mounts` entry in `devcontainer.json` — you generally don't need to re-run `ssh-agent` inside the container itself, just make sure it's running on the WSL host.

## 6. Install and set up Docker

Install Docker Desktop from the official website and log in to your account.

Under `Settings > Resources > WSL Integration`, enable integration with your distro.

The Docker daemon binds to a Unix socket, not a TCP port. By default the root user owns that socket, so other users need `sudo` to access it — the Docker daemon itself always runs as root.

To grant your user access without `sudo`:

```bash
sudo groupadd docker
sudo usermod -aG docker $USER

# restart your shell, or activate the group immediately with:
newgrp docker
docker run hello-world
```

> **Tip:** In Docker Desktop, make sure "Use the WSL 2 based engine" is checked under `Settings > General` — without it, WSL integration silently won't work.

## 7. `.devcontainer`

The project environment is set up on the `Debian` distribution through `.devcontainer` to isolate tools from the rest of the system. See [VS Code Dev Containers docs](https://code.visualstudio.com/docs/devcontainers/create-dev-container) or this repo's own `.devcontainer/devcontainer.json` for the concrete configuration.

This repo's dev container already:
- Pins Python 3.12 and installs Node LTS via devcontainer features.
- Installs the Claude Code CLI feature and forwards your host `~/.claude` config into the container.
- Forwards your host SSH agent socket (`SSH_AUTH_SOCK`) so git SSH auth works without copying keys into the container.
- Runs `uv sync` automatically as its `postCreateCommand`, so dependencies are installed on first container build without a manual step.

> **Tip:** If you change `devcontainer.json` (e.g. add a feature or mount), use the "Dev Containers: Rebuild Container" command instead of just reloading — feature and mount changes don't apply on a simple reload.
