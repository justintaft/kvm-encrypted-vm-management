# Manage Encrypted VMs

*WARNING: File contents and encryption keys may reside in memory!*
*If keys must be cleared from memory, do not use this script.*
*Instead, consider using Secure Memory Encryption, Secure Encrypted Virulization and setup LUKS/Bitlocker INSIDE the VM.*

Manages cloning, starting, and closing encrypted vms, based on unencrypted template vms.
Unencrypted VM templates disk files are assumed to be stored in ~/vms.
Encrypted VM disk files will be created in ~/vms/encrypted.

