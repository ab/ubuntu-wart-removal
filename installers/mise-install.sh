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

warn() {
  printf '%s\n' "$*" >&2
}

error() {
  echo "$@" >&2
  exit 1
}

unsupported_arch() {
  arch="$1"
  warn "unsupported architecture: $arch"
  warn ""
  warn "mise does not provide prebuilt binaries for this platform."
  warn "If Rust/Cargo is available, install from source with:"
  warn "  cargo install --locked mise"
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
    if [ "${MISE_INSTALL_MUSL-}" = "1" ] || [ "${MISE_INSTALL_MUSL-}" = "true" ]; then
      musl="-musl"
    elif [ "$(uname -o)" = "Android" ]; then
      # Android (Termux) always uses musl
      musl="-musl"
    else
      libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
      if [ -n "$libc" ]; then
        musl="-musl"
      fi
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
    unsupported_arch "$arch"
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
  else
    echo "tar.gz"
  fi
}

tar_supports_zstd() {
  if ! command -v zstd >/dev/null 2>&1; then
    false
  # tar is bsdtar
  elif tar --version | grep -q 'bsdtar'; then
    true
  # busybox tar reports a "1.3x" version that matches the GNU check below, but it
  # cannot decompress .tar.zst itself. Detect it so we fall back to the zstd pipe
  # (or a .tar.gz download) instead of running `tar -xf` on a zstd tarball.
  elif tar --version 2>&1 | grep -qi 'busybox'; then
    false
  # tar version is >= 1.31
  elif tar --version | grep -q '1\.\(3[1-9]\|[4-9][0-9]\)'; then
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
  current_version="v2026.8.14"
  current_version="${current_version#v}"

  # For current version use static checksum otherwise
  # use checksum from releases
  if [ "$version" = "$current_version" ]; then
    checksum_linux_x86_64="64d5f34aeb7a4e0e327dc1c9be66cd8162e14899a47b11901154a100285a3d61  ./mise-v2026.8.14-linux-x64.tar.gz"
    checksum_linux_x86_64_musl="3832f39c325e343f81fe3d92b2447c5d1a5eea1bc85092bb7b6c25806222647e  ./mise-v2026.8.14-linux-x64-musl.tar.gz"
    checksum_linux_arm64="940639580227bd838e3b3ea5b2084ea397399b0db162c2e4dd90b5730850e48e  ./mise-v2026.8.14-linux-arm64.tar.gz"
    checksum_linux_arm64_musl="06186cfbfe947049b21d58575fb0ea800cc26ed1375f20f4b678cb3a9d679437  ./mise-v2026.8.14-linux-arm64-musl.tar.gz"
    checksum_linux_armv7="14fe10af97875a68e45037cc44212522075519f2bf8d13b480a265de1fa9815c  ./mise-v2026.8.14-linux-armv7.tar.gz"
    checksum_linux_armv7_musl="1ef28e37bc11d9f6f7658e5cfd6db42469210dc20d597a771c43cfe38b5121d8  ./mise-v2026.8.14-linux-armv7-musl.tar.gz"
    checksum_macos_x86_64="6085d0b7c7bf8e176397c48e3f1e2025bd41d69dd50f05c08cb7ae89fb7f77b1  ./mise-v2026.8.14-macos-x64.tar.gz"
    checksum_macos_arm64="e3ba526b629c41fa7b0918f78e746ca71a7a4b0c78dbfaca9fb25676a318762e  ./mise-v2026.8.14-macos-arm64.tar.gz"
    checksum_linux_x86_64_zstd="aa6a3aa49f22de04148cd19842b6d4a0fd444dc27629402a62a7bbbd053fb5e1  ./mise-v2026.8.14-linux-x64.tar.zst"
    checksum_linux_x86_64_musl_zstd="d11af7cc220696c7afa1e1e93499fdd9d6f861d74a57dd7d50b889d7c204b8f2  ./mise-v2026.8.14-linux-x64-musl.tar.zst"
    checksum_linux_arm64_zstd="9736326aa4271dfe3fe690aae0cc4c32af64e9ca81dad1d888adcaabf12aeeee  ./mise-v2026.8.14-linux-arm64.tar.zst"
    checksum_linux_arm64_musl_zstd="8ec8ca949aa58b5601a0f545897d005bb8f8f5a7c0f22770a6788adaa563347a  ./mise-v2026.8.14-linux-arm64-musl.tar.zst"
    checksum_linux_armv7_zstd="08cec87ef494cfd3f793318d8913324261b104bf7f76c63c37ad76925962c9aa  ./mise-v2026.8.14-linux-armv7.tar.zst"
    checksum_linux_armv7_musl_zstd="fc671403ed6444bc2817cb60ee96b11d99357aa39756de2fe27fe47286363cc8  ./mise-v2026.8.14-linux-armv7-musl.tar.zst"
    checksum_macos_x86_64_zstd="bc0fe4b2110deabbf86817b0750ac6cff024a62172828f976400c56a3ef93a6f  ./mise-v2026.8.14-macos-x64.tar.zst"
    checksum_macos_arm64_zstd="85e4457a104854dcd5333f4c4e64f3055d1ffaa8dfa112ad782a9bba2aa4056c  ./mise-v2026.8.14-macos-arm64.tar.zst"

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
  download_dir="$2"
  filename="$(basename "$url")"
  file="$download_dir/$filename"

  info "mise: installing mise..."

  if command -v curl >/dev/null 2>&1; then
    debug ">" curl -#fLo "$file" "$url"
    curl -#fLo "$file" "$url"
  else
    if command -v wget >/dev/null 2>&1; then
      debug ">" wget -qO "$file" "$url"
      stderr=$(mktemp)
      wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
      rm "$stderr"
    else
      error "mise standalone install requires curl or wget but neither is installed. Aborting."
    fi
  fi

  echo "$file"
}

# Prints the version of an installed mise binary (the first field of
# `mise version`, e.g. "2025.6.0"), with any leading "v" stripped. Prints
# nothing if the binary is missing or fails to report a version.
installed_mise_version() {
  bin="$1"
  if [ -x "$bin" ]; then
    installed_version="$("$bin" version 2>/dev/null | head -n1 | cut -d' ' -f1)"
    echo "${installed_version#v}"
  fi
}

install_mise() {
  version="${MISE_VERSION:-v2026.8.14}"
  version="${version#v}"
  current_version="v2026.8.14"
  current_version="${current_version#v}"
  os="${MISE_INSTALL_OS:-$(get_os)}"
  arch="${MISE_INSTALL_ARCH:-$(get_arch)}"
  ext="${MISE_INSTALL_EXT:-$(get_ext)}"
  install_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
  install_dir="$(dirname "$install_path")"
  install_from_github="${MISE_INSTALL_FROM_GITHUB:-}"

  # Opt-in: skip the download/install if the binary already at the install
  # path matches the requested version. Only the install path is checked (not
  # the wider PATH) so that skipping never leaves install_path missing.
  skip_if_exists="${MISE_INSTALL_SKIP_IF_EXISTS-}"
  if [ "$skip_if_exists" = "1" ] || [ "$skip_if_exists" = "true" ]; then
    if [ -x "$install_path" ]; then
      existing_version="$(installed_mise_version "$install_path")"
      if [ -n "$existing_version" ] && [ "$existing_version" = "$version" ]; then
        info "mise: $install_path is already at version $version, skipping install"
        return 0
      fi
    fi
  fi
  if [ "$version" != "$current_version" ] || [ "$install_from_github" = "1" ] || [ "$install_from_github" = "true" ]; then
    tarball_url="https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-${os}-${arch}.${ext}"
  elif [ -n "${MISE_TARBALL_URL-}" ]; then
    tarball_url="$MISE_TARBALL_URL"
  else
    tarball_url="https://mise.jdx.dev/v${version}/mise-v${version}-${os}-${arch}.${ext}"
  fi

  download_dir="$(mktemp -d)"
  cache_file=$(download_file "$tarball_url" "$download_dir")
  debug "mise-setup: tarball=$cache_file"

  debug "validating checksum"
  cd "$(dirname "$cache_file")" && get_checksum "$version" "$os" "$arch" "$ext" | "$(shasum_bin)" -c >/dev/null

  # extract tarball
  if [ -d "$install_path" ]; then
    error "MISE_INSTALL_PATH '$install_path' is a directory. Please set it to a file path, e.g. '$install_path/mise'."
  fi
  mkdir -p "$install_dir"
  rm -f "$install_path"
  extract_dir="$(mktemp -d)"
  cd "$extract_dir"
  if [ "$ext" = "tar.zst" ] && ! tar_supports_zstd; then
    zstd -d -c "$cache_file" | tar --no-same-owner -xf -
  else
    tar --no-same-owner -xf "$cache_file"
  fi
  if [ "$(id -u)" = "0" ]; then
    chown 0:0 mise/bin/mise
    chmod 755 mise/bin/mise
  fi
  mv mise/bin/mise "$install_path"

  # cleanup
  cd / # Move out of $extract_dir before removing it
  rm -rf "$download_dir"
  rm -rf "$extract_dir"

  info "mise: installed successfully to $install_path"
}

after_finish_help() {
  case "${SHELL:-}" in
  */zsh)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate zsh)\\\"\" >> \"${ZDOTDIR-$HOME}/.zshrc\""
    info ""
    info "mise: run \`mise doctor\` to verify this is set up correctly"
    ;;
  */bash)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"eval \\\"\\\$($install_path activate bash)\\\"\" >> ~/.bashrc"
    info ""
    info "mise: run \`mise doctor\` to verify this is set up correctly"
    ;;
  */fish)
    info "mise: run the following to activate mise in your shell:"
    info "echo \"$install_path activate fish | source\" >> ~/.config/fish/config.fish"
    info ""
    info "mise: run \`mise doctor\` to verify this is set up correctly"
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
