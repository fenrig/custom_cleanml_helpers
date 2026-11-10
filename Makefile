SHELL := /bin/sh

BLEACHBIT_CLEANERS_DIR ?= /usr/share/bleachbit/cleaners
SYSTEM_BIN_DIR ?= /usr/bin
SYSTEMD_SYSTEM_DIR ?= /usr/lib/systemd/system
CONFIG_FILE ?= /etc/bleachbit-cache-clean.conf

INSTALL ?= install
RM ?= rm -f

CLEANER_FILES := \
	aider.xml \
	claude_code.xml \
	codex.xml \
	drkonqi.xml \
	falkon.xml \
	ferdium.xml \
	gemini_cli.xml \
	gpu.xml \
	lutris.xml \
	nextcloud.xml \
	proton.xml \
	pacman_updater.xml \
	plasma.xml \
	session.xml \
	simplex.xml \
	steam.xml \
	sublime.xml \
	thunderbird_clamav_scan.xml \
	thorium.xml \
	teams.xml \
	stremio.xml \
	yay.xml \
	custom_wine.xml \
	wowup.xml

UNIT_FILES := \
	systemd/bleachbit-cache-clean.service \
	systemd/bleachbit-cache-clean.timer

SCRIPT_FILES := \
	scripts/bleachbit-cache-clean

CONFIG_TEMPLATE := bleachbit-cache-clean.conf.example

.PHONY: all check install install-cleaners install-units install-script install-config enable disable reload uninstall

all:
	@printf '%s\n' "Targets: check, install, enable, disable, reload, uninstall"

check:
	./scripts/check

install: install-cleaners install-script install-config install-units reload

install-cleaners:
	$(INSTALL) -d "$(BLEACHBIT_CLEANERS_DIR)"
	$(INSTALL) -m 644 $(CLEANER_FILES) "$(BLEACHBIT_CLEANERS_DIR)/"
	$(INSTALL) -m 644 discord.xml "$(BLEACHBIT_CLEANERS_DIR)/custom_discord.xml"
	$(INSTALL) -m 644 vscode.xml "$(BLEACHBIT_CLEANERS_DIR)/custom_vscode.xml"

install-script:
	$(INSTALL) -d "$(SYSTEM_BIN_DIR)"
	$(INSTALL) -m 755 $(SCRIPT_FILES) "$(SYSTEM_BIN_DIR)/"

install-config:
	$(INSTALL) -d "$$(dirname "$(CONFIG_FILE)")"
	if [ -e "$(CONFIG_FILE)" ]; then \
		printf '%s\n' "Preserving existing $(CONFIG_FILE)"; \
	else \
		$(INSTALL) -m 644 "$(CONFIG_TEMPLATE)" "$(CONFIG_FILE)"; \
	fi

install-units:
	$(INSTALL) -d "$(SYSTEMD_SYSTEM_DIR)"
	$(INSTALL) -m 644 $(UNIT_FILES) "$(SYSTEMD_SYSTEM_DIR)/"

enable:
	systemctl enable --now bleachbit-cache-clean.timer

disable:
	systemctl disable --now bleachbit-cache-clean.timer

reload:
	systemctl daemon-reload

uninstall:
	-systemctl disable --now bleachbit-cache-clean.timer
	$(RM) "$(BLEACHBIT_CLEANERS_DIR)/aider.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/claude_code.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/codex.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/custom_discord.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/drkonqi.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/falkon.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/ferdium.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/gemini_cli.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/gpu.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/lutris.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/nextcloud.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/proton.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/pacman_updater.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/plasma.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/session.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/simplex.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/steam.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/sublime.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/stremio.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/thunderbird_clamav_scan.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/thorium.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/teams.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/yay.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/custom_wine.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/custom_vscode.xml" \
		"$(BLEACHBIT_CLEANERS_DIR)/wowup.xml"
	$(RM) "$(SYSTEM_BIN_DIR)/bleachbit-cache-clean"
	$(RM) "$(SYSTEMD_SYSTEM_DIR)/bleachbit-cache-clean.service" \
		"$(SYSTEMD_SYSTEM_DIR)/bleachbit-cache-clean.timer"
	systemctl daemon-reload
