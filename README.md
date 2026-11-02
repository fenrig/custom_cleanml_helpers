# custom_cleanml_helpers

System-wide BleachBit cleaners for Arch Linux desktops.

This project provides additional BleachBit CleanerML definitions for common desktop applications, games, developer tools, and graphics caches. It also installs a systemd timer that runs the cleanup separately for each regular login user on the machine.

The project is intentionally conservative: it targets disposable caches and temporary files, while avoiding application configuration, credentials, browser history, installed games, Wine registries, package databases, and other state that users may need to recover.

## How it works

The installation has four system-wide components:

1. Cleaner definitions are installed in `/usr/share/bleachbit/cleaners/`, BleachBit's trusted system cleaner directory on Linux.
2. The launcher is installed as `/usr/bin/bleachbit-cache-clean`.
3. A systemd service and timer are installed in `/usr/lib/systemd/system/`.
4. An administrator configuration file is installed at
   `/etc/bleachbit-cache-clean.conf`.

The service runs as root only to enumerate regular users and switch to each user's UID. BleachBit itself is then executed as that user, with that user's home directory and standard XDG directories:

```text
HOME              /home/user
XDG_CONFIG_HOME   /home/user/.config
XDG_CACHE_HOME    /home/user/.cache
XDG_DATA_HOME     /home/user/.local/share
```

This avoids running BleachBit against user files as root and prevents new root-owned files from being created in user home directories.

The project-specific Wine cleaner is installed as `custom_wine.xml` so it does
not overwrite BleachBit's package-provided `wine.xml` cleaner.

The launcher considers users whose UID is between `UID_MIN` and `UID_MAX` in `/etc/login.defs`, whose home directory exists, and whose home path is absolute. Root and system accounts are excluded.

## Requirements

- Arch Linux or another system with compatible Linux paths
- BleachBit installed as `/usr/bin/bleachbit`
- systemd
- `runuser` from the `util-linux` package
- `make`
- root privileges for installation and system-wide execution

Install the required Arch packages if necessary:

```bash
sudo pacman -S bleachbit util-linux
```

## Installation

From the project directory:

```bash
sudo make install
```

This installs the cleaners, launcher, service, and timer, then reloads the system service manager. Installation does not enable the timer automatically.

Enable the timer with:

```bash
sudo make enable
```

Check its state with:

```bash
systemctl status bleachbit-cache-clean.timer
systemctl list-timers bleachbit-cache-clean.timer
```

## Schedule behavior

The timer runs on the first and third Monday of each month at 03:00,
approximately every two weeks:

```ini
OnCalendar=Mon *-*-1..7 03:00
OnCalendar=Mon *-*-15..21 03:00
Persistent=true
```

`Persistent=true` causes systemd to run the service after boot when the
scheduled event was missed while the machine was powered off. The
service does not keep its own timestamp or decide whether a previous cleanup
succeeded; systemd solely controls when it is invoked.

The automatic cleaner set is controlled by `EnabledGroups` in
`/etc/bleachbit-cache-clean.conf`:

| Group | Scope |
| --- | --- |
| `safe` | Built-in browser, thumbnail, VLC, and KDE caches |
| `desktop` | Desktop, messenger, browser, editor, Plasma, and crash caches |
| `gaming` | Steam, Lutris, Wine, Proton, and GPU caches |
| `developer` | CLI tools, AUR build cache, and development-tool caches |

For example, to avoid gaming-related cleanup while retaining the other groups:

```ini
EnabledGroups=safe,desktop,developer
```

The installer creates this configuration only when it does not already exist,
so upgrades preserve local policy.

The configuration parser accepts comments and exactly one `EnabledGroups` entry.
Unknown or empty groups cause the cleanup to fail closed before any user is
processed.

Run a cleanup manually when needed:

```bash
sudo systemctl start bleachbit-cache-clean.service
```

View service output with:

```bash
journalctl -u bleachbit-cache-clean.service
```

## Included cleaners

The launcher selects these built-in BleachBit options:

- Chromium cache
- Firefox cache
- Google Chrome cache
- Thunderbird cache
- VLC memory dumps
- Thumbnail cache
- KDE cache

The project provides these additional cleaners:

| Cleaner | Scope |
| --- | --- |
| Aider | Cache, logs, and temporary files |
| Claude Code | Cache, logs, and temporary files |
| Codex CLI | Cache, logs, and temporary files |
| Discord | Chromium/Electron caches and logs |
| DrKonqi | KDE crash reports |
| Falkon | Browser caches |
| Ferdium | Chromium/Electron caches and logs |
| Gemini CLI | Cache, logs, and temporary files |
| GPU | Mesa, RADV, NVIDIA, and CUDA caches |
| Lutris | Installer, shader, temporary, and selected Wine-prefix temp files |
| Nextcloud | Compiled QML cache |
| Pacman Updater | `~/.cache/pacman-updater` |
| Plasma | Selected Plasma, KWin, and Ksplash caches |
| Proton | DXVK and VKD3D caches |
| Session | Chromium/Electron caches |
| SimpleX | Chromium/Electron caches |
| Steam | Web cache and shader cache |
| Sublime Text | Cache and index files |
| Stremio | Chromium/QtWebEngine caches |
| Microsoft Teams | Chromium/Electron caches |
| Thorium | Browser caches |
| VS Code family | VS Code, Insiders, VSCodium, Cursor, Windsurf, and Code OSS caches |
| Wine | Default-prefix temporary files and DXVK/VKD3D caches |
| Yay | AUR build cache |
| WowUp-CF | Electron/browser cache files |

Cleaner definitions are intentionally separate by application or subsystem. This makes individual scopes easy to review and keeps future additions from turning into one broad, difficult-to-audit deletion rule.

## Safety behavior

### Running applications

Cleaner definitions declare processes that should prevent cleanup while an application is running. BleachBit refuses to clean those backends when the process is detected.

The Pacman Updater cleaner uses:

```xml
<running type="exe" os="linux" same_user="false">pacman-updater</running>
```

This is intentional because Pacman Updater runs as root while the cleanup is executed as each regular user.

### Lutris and Wine

The Lutris cleaner only targets these common prefix layouts:

```text
~/Games/*/drive_c/users/*/Temp
~/Games/*/drive_c/users/*/AppData/Local/Temp
~/Games/*/drive_c/windows/temp

~/.local/share/lutris/prefixes/*/drive_c/users/*/Temp
~/.local/share/lutris/prefixes/*/drive_c/users/*/AppData/Local/Temp
~/.local/share/lutris/prefixes/*/drive_c/windows/temp
```

It does not parse Lutris's database or game YAML files, and it does not attempt to discover arbitrary custom prefix locations. This is a deliberate safety trade-off: CleanerML supports static paths and globs, but not dynamic configuration parsing.

Lutris, Wine, UMU, Proton, and GPU cleaners are guarded against common active
Wine/UMU processes. This prevents prefix and shader-cache cleanup while a game
is likely running, even when the Lutris GUI itself has already exited.

The cleaner does not remove Lutris game files, runner installations, prefixes, registries, `game-paths.json`, `versions.json`, or other Lutris metadata.

The project-specific Wine cleaner covers:

```text
~/.wine/drive_c/users/*/Temp
~/.wine/drive_c/users/*/AppData/Local/Temp
~/.wine/drive_c/windows/temp
```

The WowUp-CF cleaner targets only Electron cache directories under
`~/.config/WowUpCf`. It preserves addon metadata, preferences, cookies,
IndexedDB, logs, and downloaded addon archives.

### Trash is excluded

User trash is not selected automatically. BleachBit's `system.trash` option empties recoverable user data, so it is intentionally outside this cache-only policy.

KDE Dolphin can separately delete trash entries older than a configured age.

### Factory wipes are excluded

Some CleanerML files expose explicit factory-wipe options for tools such as Codex CLI, Claude Code, Aider, and Gemini CLI. These options are not included in the automatic launcher list.

They can remove configuration, authentication, sessions, history, or other local state and should only be selected manually.

## System caches intentionally excluded

The system service focuses on per-user application caches. It does not automatically clean these system-level resources:

- `/var/cache/pacman/pkg`
- `/var/log/journal`
- `/var/lib/pacman/sync`
- `/tmp` and `/var/tmp`
- container storage
- installed Lutris, UMU, Steam, or Proton runtimes
- package-manager stores such as pnpm

Use the native tools for those resources:

```bash
# Keep recent package versions and clean old pacman packages.
sudo paccache -r

# Enable Arch's weekly package-cache maintenance if desired.
sudo systemctl enable --now paccache.timer

# One-time journal reduction example.
sudo journalctl --rotate --vacuum-size=1G

# Inspect systemd's temporary-file cleanup policy.
systemctl status systemd-tmpfiles-clean.timer
```

Avoid `pacman -Scc` unless you intentionally want to remove the entire package cache and give up local downgrade/reinstall copies.

## Manual testing

Run the repository checks before installation:

```bash
make check
```

The check validates shell syntax, parses every XML file, loads the project
cleaners through BleachBit using an isolated temporary options directory, and
confirms that all launcher-selected cleaner options are recognized. It does
not modify the system cleaner directory or your real BleachBit configuration.

Validate all XML definitions:

```bash
for file in *.xml; do
    xmllint --noout "$file" || exit 1
done
```

Validate the launcher:

```bash
bash -n scripts/bleachbit-cache-clean
```

Preview selected cleaners for the current user before deletion:

```bash
bleachbit --preview \
    firefox.cache \
    kde.cache \
    gpu.shader_cache \
    wine.temp
```

List available cleaners:

```bash
bleachbit --list-cleaners
```

Run the system launcher manually only when you are ready to delete the selected caches for all eligible users:

```bash
sudo /usr/bin/bleachbit-cache-clean
```

## Customization

The automatic selection list is in:

```text
scripts/bleachbit-cache-clean
```

Add a cleaner option there only after its XML definition has been installed and reviewed. An option omitted from this list remains available through the BleachBit GUI or direct command-line invocation but is not automatically cleaned.

The preferred way to change the scheduled policy is the group configuration
file rather than editing the launcher. The launcher validates that every
selected cleaner is installed before processing users, and reports a summary
to the system journal after each run.

Only one cleanup can run at a time. The launcher takes a system-wide lock under
`/run/lock`; a manually started cleanup exits without doing work when a
scheduled cleanup is already active. Each per-user BleachBit invocation receives
a minimal environment with a fixed system `PATH`.

The service expects the launcher at `/usr/bin/bleachbit-cache-clean` and the Makefile installs the system unit at `/usr/lib/systemd/system`. If you change those paths, update both the Makefile and the service unit together.

## Uninstallation

Disable the timer and remove the installed files with:

```bash
sudo make uninstall
```

The uninstall target stops the timer before removing its unit files, removes
the project cleaner definitions, removes the launcher, and reloads systemd.
It intentionally preserves `/etc/bleachbit-cache-clean.conf` so a later
reinstall does not discard administrator policy.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

## Contributors

- Matthias Van Gestel

