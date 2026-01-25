## Credential sourcing (approved methods)

Choose one of these. Do not store credentials in repo files.

1. **Environment variables**
   - `DFINITY_FORUM_USERNAME`
   - `DFINITY_FORUM_PASSWORD`

2. **Local secret file (hidden from source control)**
   - Project-local (recommended): `.agent/dfinity-forum.env` (already ignored by git)
   - User-local alternative: `~/.config/dfinity-forum/credentials.env`
   - Format:
     ```
     DFINITY_FORUM_USERNAME=your-username
     DFINITY_FORUM_PASSWORD=your-password
     ```

3. **Interactive prompt (masked password input)**
   - Ask the user for credentials at runtime.
   - Use a masked input for the password (example shell prompt):
     ```
     read -r -p "Dfinity forum username: " DFINITY_FORUM_USERNAME
     read -r -s -p "Dfinity forum password: " DFINITY_FORUM_PASSWORD
     echo
     ```

4. **Skills config file (if supported by the agent host)**
   - Store credentials in the host's secret store or settings UI.
   - Map the values to `DFINITY_FORUM_USERNAME` and `DFINITY_FORUM_PASSWORD`.

## Authentication flow notes

- Login page: `https://forum.dfinity.org/login`
- The login page offers username/password, GitHub, and passkey options. Always use username/password and ignore the other methods.
- Discourse typically POSTs to `/session` on login; this is the only allowed non-GET request.
- After login, verify session with `https://forum.dfinity.org/u/<username>.json`.

## Safety constraints

- Never navigate to composer, reply, or post endpoints.
- Do not perform any action that creates, edits, reacts to, or deletes content.
