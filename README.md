Vaultix 🔐

A privacy-focused, offline-first password manager built with Flutter.

Vaultix is designed around a simple principle: your passwords should belong to you—not to a company, a cloud service, or a third-party server.

Instead of relying on online accounts or centralized infrastructure, Vaultix keeps your encrypted vault on your device. If you choose to create a backup, the encrypted vault is stored in your own Google Drive, and only the encrypted data is uploaded. Your passwords are never stored in plaintext outside your device.

---

💡 Why I Built Vaultix

Most password managers rely on cloud synchronization and user accounts. While many are secure, I wanted to build an alternative that gives users complete control over where their data lives.

Vaultix is my attempt at creating a password manager that works entirely offline while still offering optional encrypted backups for convenience.

The goal is simple:

- Privacy by default
- Offline-first architecture
- User-controlled backups
- Strong client-side encryption
- No mandatory online account

---

✨ Features

- 🔒 Offline-first — Fully functional without an internet connection.
- ☁️ Optional Google Drive Backup — Upload an encrypted backup to your own Drive account.
- 👆 Biometric Authentication — Unlock using Fingerprint or Face ID where supported.
- 🛡️ Screenshot Protection — Uses Android's "FLAG_SECURE" to help prevent screenshots and screen recording while the vault is open.
- 🔑 Password Generator — Generate strong passwords with configurable length and character sets.
- 📂 Vault Organization — Store logins, secure notes, payment cards, and identities.
- ⭐ Favorites & Recent Items
- 📊 Security Score based on password strength.
- ⚠️ Weak and Reused Password Detection
- 🎨 Modern Material 3 Interface
- 🌙 Dark & Light Themes
- 📳 Native Haptic Feedback
- 🔄 Automatic Encrypted Backup (optional)

---

🔐 Security Design

Vaultix is designed so that encryption happens before any data leaves the device.

The security workflow is straightforward:

1. Your Master Password is processed using PBKDF2 with a randomly generated salt to derive a strong encryption key.
2. Sensitive cryptographic material is protected using the platform security features available on Android and iOS where applicable.
3. Vault data is encrypted using AES-256-GCM, which provides both confidentiality and integrity.
4. If cloud backup is enabled, only the encrypted vault is uploaded to your personal Google Drive account.

At no point does Vaultix intentionally upload your passwords in plaintext.

---

📱 Screenshots

Login| Dashboard| Password Generator
login.png| home.png| generator.png

Settings| Appearance
settings_1.png| settings_2.png

---

📜 License

Vaultix is released under the GNU General Public License v3.0 (GPLv3).

I chose GPLv3 because I believe security software benefits from transparency. Anyone can inspect, learn from, and contribute to the project.

You're welcome to:

- Use the project
- Study the source code
- Modify it
- Share it

If you distribute a modified version, GPLv3 requires that the source code for those modifications also be released under the same license.

See the "LICENSE" file for the complete license text.

---

Built with ❤️ using Flutter

Designed and developed by Kiran.