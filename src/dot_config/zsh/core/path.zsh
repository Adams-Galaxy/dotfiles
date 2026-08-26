# Cross-platform PATH setup.

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"

export CUDA_HOME=/usr/local/cuda-13.3
path_prepend "$CUDA_HOME/bin"
