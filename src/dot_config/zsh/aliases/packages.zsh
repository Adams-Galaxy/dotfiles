# Flatpak package-management shorthand.
if has_command flatpak; then
  alias fp="flatpak"
  alias fpi="flatpak install"
  alias fpu="flatpak update"
  alias fpr="flatpak remove"
  alias fpl="flatpak list"
fi
