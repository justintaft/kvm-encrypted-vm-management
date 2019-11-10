#!/usr/bin/env bash

set -eu

function log() {
	echo "--" "$@"
}

function error() {
	echo "-- Error: " "$@" 1>&2
}


function mount_luks_img()  {
	local ENCRYPTED_DISK_PATH="$1"		
	local LUKS_MAPPER_NAME="$2"

        # If LUKS mapper device file does not exist, verify we have the base image.
        if [[ ! -f "$ENCRYPTED_DISK_PATH" ]]; then
        	echo "Encrypted VM file not found."
        	exit 1;
        fi

	# Create loop device for sparse file, so LUKS can operate on it
	if ! LOOP_DEVICE=$(sudo losetup --show -f "$ENCRYPTED_DISK_PATH"); then
		echo "Failed to create loop device";
		exit 1;
	fi
	
	sudo chown "$USER" "$LOOP_DEVICE"
	
	
	LUKS_MAPPER_DEVICE_NAME="${LUKS_MAPPER_NAME}"
	
	if ! ( echo "$VM_PASS" | sudo cryptsetup luksOpen "$LOOP_DEVICE" "$LUKS_MAPPER_DEVICE_NAME" ); then
		echo "Failed to open luks in $LOOP_DEVICE";
		exit 1;
	fi
	
	
	#Check to ensure LUKS mapper symlink points ot real device file 
	FINAL_DEVICE_FILE=$(realpath "/dev/mapper/${LUKS_MAPPER_DEVICE_NAME}")
	if [[ ! -e "$FINAL_DEVICE_FILE" ]] ; then
		echo "Device file does not exist."
		exit 1
	fi
	sudo chown "$USER" "$FINAL_DEVICE_FILE";
}


# Given a VM name, get it's disk path
function get_vm_disk_path() {
	VM_NAME=$1
	if ! MAPPER_NAME=$(virsh dumpxml "$VM_NAME" | grep mapper | cut -d "'"  -f2); then 
		echo "Could not get disk name for VM $VM_NAME"
		exit 1
	fi

	echo $MAPPER_NAME
}


#Get password for VM
function get_vm_pass() {
	local VM_NAME=$1
	local CURRENT_DIR=$(dirname "$(readlink -f "$0")")

	if [[ -x "${CURRENT_DIR}/get-vm-pass.sh" ]]; then
		local VM_PASS=$(./"${CURRENT_DIR}/get-vm-pass.sh")
		if [[ $? -ne 0 ]]; then
			log "-- Failed to get password."
			exit 1
		fi 
	else 
		log "Enter Password for VM $VM_NAME: " 
		IFS= read -rs VM_PASS
		if [[ $? -ne 0 ]]; then
			log "Failed to read password." 
			exit 1
		fi	
		echo $VM_PASS
	fi	
}

function normalize_vm_name()  {
	local VM_NAME=$(echo "$1" | sed "s/[^a-zA-Z0-9.]/-/g")
	if [[ $(printf "$VM_NAME" | sed 's/[.]//g' | wc -c) = "0"  ]]; then
		error "Invalid vm name ${VM_NAME}. Must not contain just dots."
		exit 1
	fi
	echo "$VM_NAME"
}

