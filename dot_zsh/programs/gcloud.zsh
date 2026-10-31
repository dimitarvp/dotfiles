# Google Cloud CLI from the official tarball: it runs on mise's python (the
# fleet's interactive python lane), never on whatever python3 a package manager
# happens to put on PATH. Google ships no bundled Python for Intel macOS.
if [[ -d "$HOME/.local/share/google-cloud-sdk" ]]; then
	export CLOUDSDK_PYTHON="$HOME/.local/share/mise/shims/python3"
fi
