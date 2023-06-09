#!/usr/bin/env bash

declare -xr INSTALL_PREFIX="${INSTALL_PREFIX:-"$HOME/.local"}"
declare -xr NVIM_APPNAME="${NVIM_APPNAME:-"kronvim"}"

declare -xr XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -xr KRONVIM_RUNTIME_DIR="${KRONVIM_RUNTIME_DIR:-"$XDG_DATA_HOME/kronvim"}"
declare -xr KRONVIM_BASE_DIR="${KRONVIM_BASE_DIR:-"$KRONVIM_RUNTIME_DIR/$NVIM_APPNAME"}"
declare -xr KRONVIM_INSTALLER_DIR="${KRONVIM_INSTALLER_DIR:-"$KRONVIM_BASE_DIR/installer"}"
declare -xr KRONVIM_CONFIG_DIR="${KRONVIM_CONFIG_DIR:-"$KRONVIM_BASE_DIR/config"}"

declare -xr GIT_REMOTE="${GIT_REMOTE:-kronis/nvim.git}"

function main() {
  	logo
	
	debug

	clean

	clone

	setup_deps

	# backup

  	symlink
}

function symlink() {
	echo ""
	echo "---------- DEBUG : SYMLINK ----------"
  ln -vs "${KRONVIM_CONFIG_DIR}" "${HOME}/.config/nvim"
	echo "-------------------------------------"
}

function backup() {
	echo ""
	echo "---------- DEBUG : BACKUP ----------"
	current_date=$(date '+%Y-%m-%d_%H-%M-%S')
	mv -v "${HOME}/.config/nvim" "${HOME}/.config/nvim.bak-${current_date}"
	echo "------------------------------------"

}

function setup_deps() {
	echo ""
	echo "---------- DEBUG : SETUP DEPENDENCIES ----------"
	echo "----------       : NPM                ----------"
	source "${KRONVIM_INSTALLER_DIR}/setup-npm.sh"
	echo ""
	echo "----------       : BREW               ----------"
	source "${KRONVIM_INSTALLER_DIR}/setup-brew.sh"
	echo ""
	echo "----------       : CARGO              ----------"
	source "${KRONVIM_INSTALLER_DIR}/setup-cargo.sh"
	echo ""
	echo "----------       : LUAROCKS           ----------"
	source "${KRONVIM_INSTALLER_DIR}/setup-luarocks.sh"
	echo "------------------------------------------------"
}

function debug() {
	echo ""
	echo "---------- DEBUG : VARIABLES ----------"
	echo "INSTALL_PREFIX: ${INSTALL_PREFIX}"
	echo "NVIM_APPNAME: ${NVIM_APPNAME}"
	echo "XDG_DATA_HOME: ${XDG_DATA_HOME}"
	echo "KRONVIM_RUNTIME_DIR: ${KRONVIM_RUNTIME_DIR}"
	echo "KRONVIM_BASE_DIR: ${KRONVIM_BASE_DIR}"
	echo "---------------------------------------"
}

function clean() {
	echo ""
	echo "---------- DEBUG : CLEAN ----------"
	rm -vrf "${KRONVIM_RUNTIME_DIR}"
	echo "-----------------------------------"
}

function clone() {
	echo ""
	echo "---------- DEBUG : CLONING ----------"
	if ! git clone --branch main \
		"https://github.com/${GIT_REMOTE}" "$KRONVIM_BASE_DIR"; then
		echo "Failed to clone repository. Installation failed."
		exit 1
	fi
	echo "-------------------------------------"
}

function logo() {
  echo ""
  echo "██╗░░██╗██████╗░░█████╗░███╗░░██╗██╗░░░██╗██╗███╗░░░███╗"
  echo "██║░██╔╝██╔══██╗██╔══██╗████╗░██║██║░░░██║██║████╗░████║"
  echo "█████═╝░██████╔╝██║░░██║██╔██╗██║╚██╗░██╔╝██║██╔████╔██║"
  echo "██╔═██╗░██╔══██╗██║░░██║██║╚████║░╚████╔╝░██║██║╚██╔╝██║"
  echo "██║░╚██╗██║░░██║╚█████╔╝██║░╚███║░░╚██╔╝░░██║██║░╚═╝░██║"
  echo "╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝"
  echo ""
}
main
