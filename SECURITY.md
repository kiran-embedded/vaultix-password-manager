# Security & Threat Model

Vaultix Password Manager is built with an uncompromising, zero-trust security architecture. Our primary goal is to protect user vaults against both external threats and localized device compromises. 

## Threat Model

We operate under the assumption that the host environment (the user's device) may be actively hostile. As such, Vaultix relies on Hardware-Backed Attestation and Runtime Application Self-Protection (RASP) to ensure the execution environment is pristine before any sensitive vault data is loaded.

The following attack vectors are heavily mitigated:
- **Device Rooting & Jailbreaking:** Access to the device's root directory or elevated privileges.
- **Dynamic Instrumentation & Hooking:** Tools like Frida, Magisk, or Xposed Framework attempting to inject code at runtime.
- **Application Repackaging (Anti-Tampering):** Modifying the source code, altering resources, or re-signing the APK.
- **Environment Spoofing:** Emulators, custom ROMs, or fake hardware identifiers.

---

## Built-In Protections

### 1. Strict Anti-Tampering (Source Code & APK Integrity)
Vaultix is bound to a strict cryptographic signature and runtime checksum verification. 
**Even if an attacker clones this repository, modifying a single line of code and recompiling the application will completely break the app's execution.** 
The application validates its own APK signature, classes.dex checksum, and official installation source at runtime. If the app is repackaged, tampered with, or signed with an unofficial developer key, the security engine will forcefully crash the app to prevent malicious payload execution. 

### 2. Runtime Application Self-Protection (RASP)
Vaultix utilizes industry-leading RASP (powered by Talsec). The app continuously monitors its own memory space and execution state. Any attempt to attach a debugger, hook into the application lifecycle, or monitor application memory will trigger an immediate, irreversible app termination.

### 3. Hardware-Backed Keystore
All cryptographic operations rely on the Android Hardware-Backed Keystore. Master passwords and encryption keys never leave the secure enclave. Extracting the application data directory will only yield securely encrypted AES-256-GCM ciphertext that cannot be decrypted outside of the original device's Trusted Execution Environment (TEE).

### 4. Zero-Knowledge Architecture
Vaultix operates entirely offline and locally. We do not transmit, sync, or backup your vault to external servers. Your master password is never stored on disk; it is only used to derive the encryption keys on the fly using Argon2/PBKDF2. 

---

## Reporting a Vulnerability

If you believe you have discovered a vulnerability that bypasses our RASP, Anti-Tamper, or Encryption implementations, please responsibly disclose it. 

**Do NOT create public GitHub issues for critical security vulnerabilities.**
Please email your findings directly to the repository maintainers so a patch can be developed safely before public disclosure.

*We take the security of our users very seriously and will investigate all legitimate reports immediately.*
