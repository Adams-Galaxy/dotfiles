# Chezmoi migration plan

## Target end state

- `chezmoi` is the entrypoint for managing dotfiles
- shared shell logic is separated from OS-specific logic
- private and machine-specific values are excluded from Git
- bootstrap scripts handle dependency installation
- Zsh loads from small, purpose-built modules

## Proposed structure

- `dot_config/zsh/.zshrc.tmpl`: tiny entrypoint
- `dot_config/zsh/env/`: shared environment and PATH setup
- `dot_config/zsh/os/macos.zsh`: macOS-only behavior
- `dot_config/zsh/os/linux.zsh`: Linux-only behavior
- `dot_config/zsh/local/local.zsh.tmpl`: machine-private overrides
- `scripts/`: repo-local helpers, not managed by chezmoi
- `run_once_*.sh.tmpl`: bootstrap tasks for installs and setup
- `private_*.tmpl`: secrets or machine-specific values

## Migration phases

### Phase 1: stabilize the shell layout

- make `.zshrc` a loader only
- move aliases, functions, PATH, completion, prompt, and projects into separate modules
- remove hardcoded user paths from shared files
- isolate macOS-only and Linux-only code

### Phase 2: add chezmoi structure

- add chezmoi-managed targets
- create the templated Zsh entrypoint
- add `.chezmoiignore` for files that should not be managed
- add a `README` with bootstrap instructions

### Phase 2b: keep repo-local helpers separate

- put helper scripts in `scripts/`
- keep docs in `docs/`
- ignore both with `.chezmoiignore`

### Phase 3: bootstrap automation

- create one-time install scripts
- install shell tools and dependencies
- create local directories that the shell expects
- make the setup idempotent

### Phase 4: private and machine-specific config

- move secrets into private templates
- move local-only values into ignored local files
- keep shared Git history clean and reproducible

### Phase 5: verification and cleanup

- test on macOS
- test on Linux
- simplify any duplicated logic
- document every supported tool and dependency

## Migration rules

- one file should have one job
- shared config must not assume a specific OS
- OS-specific logic must not leak into shared modules
- no hardcoded username-based paths in shared files
- optional tools should fail gracefully if not installed

## First implementation slice

1. create the repo scaffold
2. split Zsh into shared and OS-specific modules
3. introduce chezmoi templates
4. add bootstrap scripts
5. validate shell startup
