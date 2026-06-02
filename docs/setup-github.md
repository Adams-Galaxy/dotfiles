# Publish dotfiles to GitHub and apply with chezmoi

These are the exact commands to push this repo to GitHub under `Adams-Galaxy` (SSH and HTTPS options) and apply it with `chezmoi` on any machine.

1. From your local repo root (this repo is at `/Users/adamwilliams/.dotfiles`):

```sh
cd /Users/adamwilliams/.dotfiles
# initialize git (if not already a repo)
git init
git add .
git commit -m "Initial chezmoi-based dotfiles"
# create the main branch
git branch -M main
# add remote (SSH)
git remote add origin git@github.com:Adams-Galaxy/dotfiles.git
# or via HTTPS
# git remote add origin https://github.com/Adams-Galaxy/dotfiles.git
# push
git push -u origin main
```

2. On any machine with chezmoi installed, apply the dotfiles:

```sh
# SSH (preferred if you use SSH keys)
chezmoi init --apply git@github.com:Adams-Galaxy/dotfiles.git

# or HTTPS
# chezmoi init --apply https://github.com/Adams-Galaxy/dotfiles.git
```

3. After chezmoi finishes, run the one-time bootstrap (if present):

```sh
# if a template run_once_01_bootstrap.sh.tmpl exists chezmoi will render it to your home and may run it.
# Alternatively, run the repository helper locally (not managed by chezmoi):
sh ~/dotfiles/scripts/bootstrap.sh
```

Notes:
- I intentionally did not commit any SSH private keys. Keep `~/.ssh/id_*` and other secrets out of Git. Use `private_*.tmpl` with chezmoi if you want machine-private templating.
- Edit the templates (e.g., `dot_config/git/.gitconfig.tmpl`) if you want to change name/email before publishing.
