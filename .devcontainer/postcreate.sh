#!/usr/bin/env bash

set -euo pipefail

# Install Oh My Bash
# Ensure basic networking/tools and locales are present before doing user-level installs
need_install=()
if ! command -v curl >/dev/null 2>&1; then need_install+=(curl); fi
if ! command -v git >/dev/null 2>&1; then need_install+=(git); fi
if ! command -v locale >/dev/null 2>&1; then need_install+=(locales); fi

# Only try apt/dpkg installs on Debian/Ubuntu-like systems
if [ ${#need_install[@]} -gt 0 ]; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "Installing prerequisite packages: ${need_install[*]} ca-certificates"
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends "${need_install[@]}" ca-certificates
    else
        echo "Note: missing tools: ${need_install[*]}. Please install them manually on this system."
    fi
fi

# Generate locales based on the environment (non-interactive)
# Collect locale preferences from common env vars and normalize to UTF-8
DESIRED_VARS=(LC_ALL LANG LC_CTYPE LC_MESSAGES LC_NUMERIC LC_TIME LC_COLLATE)
declare -a WANT_LOCALES=()
for v in "${DESIRED_VARS[@]}"; do
    val="${!v-}"
    if [ -n "$val" ]; then
        # Extract base locale (strip encoding and modifiers like @variant)
        base=$(printf "%s" "$val" | cut -d'.' -f1 | cut -d'@' -f1)
        base=$(printf "%s" "$base" | tr -d '[:space:]')
        if [ -n "$base" ] && [ "$base" != "C" ] && [ "$base" != "POSIX" ]; then
            WANT_LOCALES+=("${base}.UTF-8")
        fi
    fi
done

# If we didn't detect anything sensible, fall back to en_GB.UTF-8
if [ ${#WANT_LOCALES[@]} -eq 0 ]; then
    WANT_LOCALES=("en_GB.UTF-8")
fi

# Deduplicate and only generate locales that are missing on the system
WANT_UNIQ=$(printf "%s\n" "${WANT_LOCALES[@]}" | awk '!seen[$0]++')
MISSING=()
for L in $WANT_UNIQ; do
    if ! locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -q "^$(printf "%s" "$L" | tr '[:upper:]' '[:lower:]' | sed 's/\./\\./')$"; then
        MISSING+=("$L")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Generating locales: ${MISSING[*]}"
    if command -v locale-gen >/dev/null 2>&1; then
        # Ensure /etc/locale.gen contains the requested locales, then run locale-gen
        if [ -w /etc/locale.gen ] || sudo test -w /etc/locale.gen; then
            for L in "${MISSING[@]}"; do
                # locale.gen expects lines like: en_GB.UTF-8 UTF-8
                entry="${L} UTF-8"
                if ! sudo grep -xFq "$entry" /etc/locale.gen 2>/dev/null; then
                    echo "Adding $entry to /etc/locale.gen"
                    echo "$entry" | sudo tee -a /etc/locale.gen >/dev/null
                fi
            done
            sudo locale-gen || true
        else
            # Fall back to attempting to call locale-gen with args (some systems support this)
            sudo locale-gen ${MISSING[*]} || true
        fi
        # Try to set LANG to the first requested locale; don't fail the script if it errors
        if ! sudo update-locale LANG="${MISSING[0]}" 2>/tmp/update-locale.err; then
            echo "Warning: update-locale failed, see /tmp/update-locale.err"
            sed -n '1,200p' /tmp/update-locale.err || true
        fi
    else
        echo "locale-gen not available; please generate locales manually: ${MISSING[*]}"
    fi
fi

# Install Oh My Bash into the correct user home
if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "Installing Oh My Bash..."

    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "$HOME/.oh-my-bash"
fi

# Install GitHub CLI

echo "Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt-get update \
        && sudo apt-get install -y gh
fi

# Install Podman if not already installed
echo "Installing Podman..."
if ! command -v podman &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y podman
fi

# Configure Podman to use the host's Podman socket
export CONTAINER_HOST="unix:///run/podman/podman.sock"
if ! grep -q "CONTAINER_HOST" ~/.bashrc 2>/dev/null; then
    echo 'export CONTAINER_HOST="unix:///run/podman/podman.sock"' >> ~/.bashrc
fi

# Install Kind (Kubernetes in Docker)
echo "Installing Kind..."
if ! command -v kind &> /dev/null; then
    curl -sSfLo /tmp/kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x /tmp/kind
    sudo install -o root -g root -m 0755 /tmp/kind /usr/local/bin/kind
fi

# Check if cluster already exists
CLUSTER_EXISTS=false
if KIND_EXPERIMENTAL_PROVIDER=podman kind get clusters 2>/dev/null | grep -q "dev-cluster"; then
    echo "✅ Kind cluster 'dev-cluster' already exists"
    CLUSTER_EXISTS=true
fi

# Create cluster if it doesn't exist
if [ "$CLUSTER_EXISTS" = false ]; then
    echo "Creating Kind cluster with Podman..."
    KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster --name dev-cluster --wait 5m
    echo "✅ Kind cluster created successfully"
fi

# Fix kubeconfig permissions
sudo chown -R vscode:vscode ~/.kube 2>/dev/null || true

# Update kubeconfig with the correct cluster IP (after rebuild on kind network)
if [ -f ~/.kube/config ]; then
    CONTAINER_IP=$(podman inspect dev-cluster-control-plane --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    if [ -n "$CONTAINER_IP" ]; then
        sed -i "s|https://[0-9.]*:[0-9]*|https://${CONTAINER_IP}:6443|g" ~/.kube/config
        echo "✅ Updated kubeconfig to use cluster IP: $CONTAINER_IP"
    fi
fi

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Kind cluster is running and kubectl is configured."
echo "Test with: kubectl cluster-info"
echo ""
echo "To deploy the DNS stack:"
echo "  cd dns"
echo "  ./deploy.sh"
echo ""

