#!/bin/sh
# Based on Deno installer: Copyright 2019 the Deno authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.

set -e

main() {
	# Parse arguments
	non_interactive=false
	setup_path=false
	version="latest"
	
	for arg in "$@"; do
		case $arg in
			--non-interactive)
				non_interactive=true
				;;
			--setup-path)
				setup_path=true
				;;
			prerel|pre)
				version="$arg"
				;;
			latest)
				version="latest"
				;;
			--*)
				# Ignore unknown flags
				;;
			*)
				# Treat as version if it looks like a version
				if echo "$arg" | grep -qE '^v?[0-9]'; then
					version="$arg"
				fi
				;;
		esac
	done
	
	os=$(uname -s)
	arch=$(uname -m)

	flyctl_uri=$(curl -s ${FLY_FORCE_TRACE:+ -H "Fly-Force-Trace: $FLY_FORCE_TRACE"} https://api.fly.io/app/flyctl_releases/$os/$arch/$version)
	if [ ! "$flyctl_uri" ]; then
		echo "Error: Unable to find a flyctl release for $os/$arch/$version - see github.com/superfly/flyctl/releases for all versions" 1>&2
		exit 1
	fi

	flyctl_install="${FLYCTL_INSTALL:-$HOME/.fly}"

	bin_dir="$flyctl_install/bin"
	tmp_dir="$flyctl_install/tmp"
	exe="$bin_dir/flyctl"
	simexe="$bin_dir/fly"

	mkdir -p "$bin_dir"
	mkdir -p "$tmp_dir"

	if ! curl_info=$(curl -q --fail --location --progress-bar \
		--retry 5 \
		--write-out '%{http_code} %{url_effective}' \
		--output "$tmp_dir/flyctl.tar.gz" \
		"$flyctl_uri"); then
		echo "Error: failed to download flyctl (last: $curl_info)" 1>&2
		exit 1
	fi
	# extract to tmp dir so we don't open existing executable file for writing:
	tar -C "$tmp_dir" -xzf "$tmp_dir/flyctl.tar.gz"
	chmod +x "$tmp_dir/flyctl"
	# atomically rename into place:
	mv "$tmp_dir/flyctl" "$exe"
	rm "$tmp_dir/flyctl.tar.gz"

	ln -sf $exe $simexe

	if [ "${1}" = "prerel" ] || [ "${1}" = "pre" ]; then
		"$exe" version -s "shell-prerel"
	else
		"$exe" version -s "shell"
	fi

	echo "flyctl was installed successfully to $exe"
	if command -v flyctl >/dev/null; then
		echo "Run 'flyctl --help' to get started"
	else
		# Determine shell-specific values
		case $SHELL in
		/bin/zsh|*/zsh)
			shell_rc="~/.zshrc"
			rc_file="$HOME/.zshrc"
			rc_d_dir="$HOME/.zshrc.d"
			rc_d_file="$rc_d_dir/99-flyctl.zsh"
			;;
		*)
			shell_rc="~/.bashrc"
			rc_file="$HOME/.bashrc"
			rc_d_dir="$HOME/.bashrc.d"
			rc_d_file="$rc_d_dir/99-flyctl.sh"
			;;
		esac

		# Determine which config file to use (preference order):
		# 1. .bashrc.d or .zshrc.d directory if it exists
		# 2. Create .bashrc.d or .zshrc.d if the rc file sources it (not commented)
		# 3. Use the main rc file (.bashrc or .zshrc)
		# 4. For bash, fall back to .bash_profile if no .bashrc
		config_file=""
		if [ -d "$rc_d_dir" ]; then
			# Use existing .d directory
			config_file="$rc_d_file"
		elif [ -f "$rc_file" ] && grep -qE '^[^#]*(\.|source).*'"$(basename "$rc_d_dir")" "$rc_file" 2>/dev/null; then
			# Create .d directory since rc file sources it
			mkdir -p "$rc_d_dir"
			config_file="$rc_d_file"
		elif [ -f "$rc_file" ]; then
			# Use main rc file
			config_file="$rc_file"
		elif echo "$SHELL" | grep -q bash && [ -f "$HOME/.bash_profile" ]; then
			# Bash-only fallback: use .bash_profile if no .bashrc
			config_file="$HOME/.bash_profile"
			shell_rc="~/.bash_profile"
		fi

		# Check if already configured
		if [ -n "$config_file" ] && grep -qE "(FLYCTL_INSTALL|\.fly/bin)" "$config_file" 2>/dev/null; then
			echo ""
			echo "flyctl PATH is already configured in $config_file"
			echo ""
			echo "To use the newly installed version in this terminal, run:"
			echo "  source $shell_rc"
			echo ""
			echo "Or simply open a new terminal."
		else
			# Not configured yet, determine response
			if [ "$setup_path" = "true" ]; then
				# --setup-path flag specified
				response="y"
			elif [ "$non_interactive" = "true" ] || [ ! -t 1 ]; then
				# Non-interactive mode (flag or piped input)
				response="n"
			else
				# Interactive terminal, prompt user
				echo "flyctl is not in your PATH. Would you like to add it automatically? (Y/n)"
				read -r response < /dev/tty
			fi

			if [ "$response" = "y" ] || [ "$response" = "Y" ] || [ "$response" = "yes" ] || [ "$response" = "Yes" ] || [ "$response" = "" ]; then
				if [ -n "$config_file" ]; then
					echo "" >> "$config_file"
					echo "# Added by flyctl installer" >> "$config_file"
					echo "export FLYCTL_INSTALL=\"$flyctl_install\"" >> "$config_file"
					echo "export PATH=\"\$FLYCTL_INSTALL/bin:\$PATH\"" >> "$config_file"
					echo ""
					echo "flyctl PATH configured successfully in $config_file"
					echo ""
					echo "To start using flyctl in this terminal, run:"
					echo "  source $shell_rc"
					echo ""
					echo "Or simply open a new terminal (flyctl will be available automatically)."
				else
					echo ""
					echo "Could not determine shell configuration file to update."
					echo "Please manually add the directory to your shell profile:"
					echo ""
					echo "  export FLYCTL_INSTALL=\"$flyctl_install\""
					echo "  export PATH=\"\$FLYCTL_INSTALL/bin:\$PATH\""
					echo ""
					echo "Add this to ~/.bashrc, ~/.zshrc, or your shell's equivalent."
				fi
			else
				echo "Manually add the directory to your $shell_rc (or similar)"
				echo "  export FLYCTL_INSTALL=\"$flyctl_install\""
				echo "  export PATH=\"\$FLYCTL_INSTALL/bin:\$PATH\""
			fi
		fi
	fi
}

main "$@"
