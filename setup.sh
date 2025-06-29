#!/usr/bin/env bash
# ref: https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh

set -e

# Debian / Ubuntu
setup_debian() {
  # Install the list of packages
  sudo rm -rf /var/lib/apt/lists/*
  sudo apt-get update -y
  sudo apt-get -y install --no-install-recommends \
    fish \
    net-tools \
    gnupg2 \
    vim

  # Clean up
  sudo apt-get -y clean
  sudo rm -rf /var/lib/apt/lists/*

  # Setup timezone
  sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
}

# RedHat / RockyLinux / CentOS / Fedora
setup_redhat() {
  # Install the list of packages
  local install_cmd=microdnf
  if ! type microdnf > /dev/null 2>&1; then
    install_cmd=dnf
    if ! type dnf > /dev/null 2>&1; then
      install_cmd=yum
    fi
  fi
  sudo ${install_cmd} check-update
  sudo ${install_cmd} -y install \
    fish \
    net-tools \
    gnupg2 \
    vim

  # Setup timezone
  sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
}

# Alpine Linux
setup_alpine() {
  # Install the list of packages
  sudo apk update
  sudo apk add --no-cache \
    fish \
    net-tools \
    gnupg \
    vim

  # Setup timezone
  sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
}

# ******************
# ** Main section **
# ******************

# if [ "$(id -u)" -ne 0 ]; then
#     echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
#     exit 1
# fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
  ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
  ADJUSTED_ID="rhel"
elif [ "${ID}" = "alpine" ]; then
  ADJUSTED_ID="alpine"
else
  echo "Linux distro ${ID} not supported."
  exit 1
fi

# Install packages for appropriate OS
case "${ADJUSTED_ID}" in
  "debian")
    setup_debian
    ;;
  "rhel")
    setup_redhat
    ;;
  "alpine")
    setup_alpine
    ;;
esac

# **********************
# ** Platform section **
# **********************

if [ "$CODESPACES" = "true" ]; then
  echo "Running in GitHub Codespaces"
elif [ "$DEVCONTAINER" = "true" ]; then
    echo "Running in devcontainer CLI"
elif [ -n "$CODER_WORKSPACE_NAME" ]; then
    echo "Running in Coder"
elif [ -n "$GITPOD_WORKSPACE_ID" ]; then
    echo "Running in Gitpod"
else
    echo "Running in a different environment"
fi

# For remote environments, configure gitconfig
if [ "$REMOTE_CONTAINERS" != "true" ]; then
  git config --global http.cookiefile "~/.gitcookies"
  git config --global commit.signoff true
  git config --global commit.gpgsign "true"
  git config --global tag.gpgsign "true"
  git config --global url."git://github.com/".insteadOf "https://github.com/" # Settings for performing go mod download, etc. from a private repositories
  git config --global init.defaultBranch main
  git config --global core.editor vi
  git config --global color.ui auto
  git config --global push.default current
  git config --global merge.ff false
  git config --global pull.rebase true
  git config --global rebase.rebaseMerges true
  # aliases
  git config --global alias.st status
  git config --global alias.co checkout
  git config --global alias.com "checkout main"
  git config --global alias.coms "checkout master"
  git config --global alias.sw switch
  git config --global alias.swm "switch main"
  git config --global alias.swms "switch master"
  git config --global alias.di diff
  git config --global alias.dic "diff --cached"
  git config --global alias.lo "log --graph -n 20 --pretty=format:'%C(yellow)%h%C(cyan)%d%Creset %s %C(green)- %an, %cr%Creset'"
  git config --global alias.lp "log --oneline -n 20 -p"
  git config --global alias.ls "log --stat --abbrev-commit"
  git config --global alias.br branch
  git config --global alias.fe fetch
fi

# ********************
# ** Common section **
# ********************

# Setup fish shell & omf
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install
fish install --path=~/.local/share/omf --config=~/.config/omf --noninteractive --yes
rm install
sudo chsh --shell $(which fish) $USER

# Setup fish aliases
mkdir -p $HOME/.config/fish/conf.d
cat > $HOME/.config/fish/conf.d/alias.fish << 'EOF'
alias kc kubectl
alias gi git
alias gc gcloud
alias tf terraform
alias ks kustomize
alias he helm
EOF
