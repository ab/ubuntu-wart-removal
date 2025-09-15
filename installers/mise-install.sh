#!/bin/sh
set -eu

#region logging setup
if [ "${MISE_DEBUG-}" = "true" ] || [ "${MISE_DEBUG-}" = "1" ]; then
  debug() {
    echo "$@" >&2
  }
else
  debug() {
    :
  }
fi

if [ "${MISE_QUIET-}" = "1" ] || [ "${MISE_QUIET-}" = "true" ]; then
  info() {
    :
  }
else
  info() {
    echo "$@" >&2
  }
fi

error() {
  echo "$@" >&2
  exit 1
}
#endregion

#region environment setup
get_os() {
  os="$(uname -s)"
  if [ "$os" = Darwin ]; then
    echo "macos"
  elif [ "$os" = Linux ]; then
    echo "linux"
  else
    error "unsupported OS: $os"
  fi
}

get_arch() {
  musl=""
  if type ldd >/dev/null 2>/dev/null; then
    libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
    if [ -n "$libc" ]; then
      musl="-musl"
    fi
  fi
  arch="$(uname -m)"
  if [ "$arch" = x86_64 ]; then
    echo "x64$musl"
  elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
    echo "arm64$musl"
  elif [ "$arch" = armv7l ]; then
    echo "armv7$musl"
  else
    error "unsupported architecture: $arch"
  fi
}

get_ext() {
  if [ -n "${MISE_INSTALL_EXT:-}" ]; then
    echo "$MISE_INSTALL_EXT"
  elif [ -n "${MISE_VERSION:-}" ] && echo "$MISE_VERSION" | grep -q '^v2024'; then
    # 2024 versions don't have zstd tarballs
    echo "tar.gz"
  elif tar_supports_zstd; then
    echo "tar.zst"
  elif command -v zstd >/dev/null 2>&1; then
    echo "tar.zst"
  else
    echo "tar.gz"
  fi
}

tar_supports_zstd() {
  # tar is bsdtar or version is >= 1.31
  if tar --version | grep -q 'bsdtar' && command -v zstd >/dev/null 2>&1; then
    true
  elif tar --version | grep -q '1\.(3[1-9]|[4-9][0-9]'; then
    true
  else
    false
  fi
}

shasum_bin() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    error "mise install requires shasum or sha256sum but neither is installed. Aborting."
  fi
}

get_checksum() {
  version=$1
  os=$2
  arch=$3
  ext=$4
  url="https://github.com/jdx/mise/releases/download/v${version}/SHASUMS256.txt"

  # For current version use static checksum otherwise
  # use checksum from releases
  if [ "$version" = "v2025.9.10" ]; then
    checksum_linux_x86_64="a2a4221da822dee65985764b93f23889c7c763a2abcff5780bec7408b90960d9  ./mise-v2025.9.10-linux-x64.tar.gz"
    checksum_linux_x86_64_musl="234af6af6826ddf0f75cef596f0bf28c94b2d5c704f5fed89785a52da3e74605  ./mise-v2025.9.10-linux-x64-musl.tar.gz"
    checksum_linux_arm64="5105322fd754809d84ec6a1bceb04efb69627aa1db017d5a464c5c05669032e5  ./mise-v2025.9.10-linux-arm64.tar.gz"
    checksum_linux_arm64_musl="c43a26d3a3e8bd9ac47692f2d20484ee4e184ff24888665ed9f4b752eade844a  ./mise-v2025.9.10-linux-arm64-musl.tar.gz"
    checksum_linux_armv7="e9c1d77e4b67132f3c1f728a0a19dd89560ea665f767b9c401dc7c1b11cb2ea9  ./mise-v2025.9.10-linux-armv7.tar.gz"
    checksum_linux_armv7_musl="c894729819b130e17acea1406a9bc16bb60b4e57c02a9d05ca51368fbb823a1b  ./mise-v2025.9.10-linux-armv7-musl.tar.gz"
    checksum_macos_x86_64="9cb1f56d7065c80d9acab5d44a548916fb50101f807c411ede764117ddc05f33  ./mise-v2025.9.10-macos-x64.tar.gz"
    checksum_macos_arm64="16dc29468ea40497b68274dbf7cef40cc92b355b8e6f4b796133d28d0c877960  ./mise-v2025.9.10-macos-arm64.tar.gz"
    checksum_linux_x86_64_zstd="bd15fb4004e7f95478e058f20463de9f19bff5c7cf3e4678e787d5d41f56c43e  ./mise-v2025.9.10-linux-x64.tar.zst"
    checksum_linux_x86_64_musl_zstd="d8463f7be6a4ae4628c558debf505125f981503c425c338beced5c4a20ca709e  ./mise-v2025.9.10-linux-x64-musl.tar.zst"
    checksum_linux_arm64_zstd="5920afc0bac0c25f66be3196d07cae95d4283a2e32018ee7105a95b9bb1afeea  ./mise-v2025.9.10-linux-arm64.tar.zst"
    checksum_linux_arm64_musl_zstd="5c1c07cefaecb4478fffa02ae3a8e1db9a0aa4eb1d8536ce0264e19a11fc1e98  ./mise-v2025.9.10-linux-arm64-musl.tar.zst"
    checksum_linux_armv7_zstd="777d2f68246009b32262209f7b412ad5db6d8ba07c9c53c4f0a01b6c686d34d4  ./mise-v2025.9.10-linux-armv7.tar.zst"
    checksum_linux_armv7_musl_zstd="417148685e5d7332c771cf3703496b61b56ccfe13417efe9b2d5468e52342dde  ./mise-v2025.9.10-linux-armv7-musl.tar.zst"
    checksum_macos_x86_64_zstd="9970dff115bf3161379da0665b8d244030002b964c108371d7ba40dc06c9c120  ./mise-v2025.9.10-macos-x64.tar.zst"
    checksum_macos_arm64_zstd="a098f8518e1fe57d26dedb9a443084e6f85a98d3c003c73318a551257b2d5458  ./mise-v2025.9.10-macos-arm64.tar.zst"

    # TODO: refactor this, it's a bit messy
    if [ "$ext" = "tar.zst" ]; then
      if [ "$os" = "linux" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_linux_x86_64_zstd"
        elif [ "$arch" = "x64-musl" ]; then
          echo "$checksum_linux_x86_64_musl_zstd"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_linux_arm64_zstd"
        elif [ "$arch" = "arm64-musl" ]; then
          echo "$checksum_linux_arm64_musl_zstd"
        elif [ "$arch" = "armv7" ]; then
          echo "$checksum_linux_armv7_zstd"
        elif [ "$arch" = "armv7-musl" ]; then
          echo "$checksum_linux_armv7_musl_zstd"
        else
          warn "no checksum for $os-$arch"
        fi
      elif [ "$os" = "macos" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_macos_x86_64_zstd"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_macos_arm64_zstd"
        else
          warn "no checksum for $os-$arch"
        fi
      else
        warn "no checksum for $os-$arch"
      fi
    else
      if [ "$os" = "linux" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_linux_x86_64"
        elif [ "$arch" = "x64-musl" ]; then
          echo "$checksum_linux_x86_64_musl"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_linux_arm64"
        elif [ "$arch" = "arm64-musl" ]; then
          echo "$checksum_linux_arm64_musl"
        elif [ "$arch" = "armv7" ]; then
          echo "$checksum_linux_armv7"
        elif [ "$arch" = "armv7-musl" ]; then
          echo "$checksum_linux_armv7_musl"
        else
          warn "no checksum for $os-$arch"
        fi
      elif [ "$os" = "macos" ]; then
        if [ "$arch" = "x64" ]; then
          echo "$checksum_macos_x86_64"
        elif [ "$arch" = "arm64" ]; then
          echo "$checksum_macos_arm64"
        else
          warn "no checksum for $os-$arch"
        fi
      else
        warn "no checksum for $os-$arch"
      fi
    fi
  else
    if command -v curl >/dev/null 2>&1; then
      debug ">" curl -fsSL "$url"
      checksums="$(curl --compressed -fsSL "$url")"
    else
      if command -v wget >/dev/null 2>&1; then
        debug ">" wget -qO - "$url"
        stderr=$(mktemp)
        checksums="$(wget -qO - "$url")"
      else
        error "mise standalone install specific version requires curl or wget but neither is installed. Aborting."
      fi
    fi
    # TODO: verify with minisign or gpg if available

    checksum="$(echo "$checksums" | grep "$os-$arch.$ext")"
    if ! echo "$checksum" | grep -Eq "^([0-9a-f]{32}|[0-9a-f]{64})"; then
      warn "no checksum for mise $version and $os-$arch"
    else
      echo "$checksum"
    fi
  fi
}

#endregion

download_file() {
  url="$1"
  filename="$(basename "$url")"
  cache_dir="$(mktemp -d)"
  file="$cache_dir/$filename"

  info "mise: installing mise..."

  if command -v curl >/dev/null 2>&1; then
    debug ">" curl -#fLo "$file" "$url"
    curl -#fLo "$file" "$url"
  else
    if command -v wget >/dev/null 2>&1; then
      debug ">" wget -qO "$file" "$url"
      stderr=$(mktemp)
      wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
    else
      error "mise standalone install requires curl or wget but neither is installed. Aborting."
    fi
  fi

  echo "$file"
}

install_mise() {
  version="${MISE_VERSION:-v2025.9.10}"
  version="${version#v}"
  os="${MISE_INSTALL_OS:-$(get_os)}"
  arch="${MISE_INSTALL_ARCH:-$(get_arch)}"
  ext="${MISE_INSTALL_EXT:-$(get_ext)}"
  install_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
  install_dir="$(dirname "$install_path")"
  install_from_github="${MISE_INSTALL_FROM_GITHUB:-}"
  if [ "$version" != "v2025.9.10" ] || [ "$install_from_github" = "1" ] || [ "$install_from_github" = "true" ]; then
    tarball_url="https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-${os}-${arch}.${ext}"
  elif [ -n "${MISE_TARBALL_URL-}" ]; then
    tarball_url="$MISE_TARBALL_URL"
  else
    tarball_url="https://mise.jdx.dev/v${version}/mise-v${version}-${os}-${arch}.${ext}"
  fi

  cache_file=$(download_file "$tarball_url")
  debug "mise-setup: tarball=$cache_file"

  debug "validating checksum"
  cd "$(dirname "$cache_file")" && get_checksum "$version" "$os" "$arch" "$ext" | "$(shasum_bin)" -c >/dev/null

  # extract tarball
  mkdir -p "$install_dir"
  rm -rf "$install_path"
  cd "$(mktemp -d)"
  if [ "$ext" = "tar.zst" ] && ! tar_supports_zstd; then
    zstd -d -c "$cache_file" | tar -xf -
  else
    tar -xf "$cache_file"
  fi
  mv mise/bin/mise "$install_path"
  info "mise: installed successfully to $install_path"
}

after_finish_help() {
  case "${SHELL:-}" in
  */zsh)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate zsh)\\\"\" >> \"${ZDOTDIR-$HOME}/.zshrc\""
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  */bash)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate bash)\\\"\" >> ~/.bashrc"
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  */fish)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"$install_path activate fish | source\" >> ~/.config/fish/config.fish"
    info ""
    info "mise: run \`mise doctor\` to verify this is setup correctly"
    ;;
  *)
    info "mise: run \`$install_path --help\` to get started"
    ;;
  esac
}

install_mise
if [ "${MISE_INSTALL_HELP-}" != 0 ]; then
  after_finish_help
fi
