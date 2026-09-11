# Git and SSH config

Git configuration supplies the author name and email for commits. SSH configuration selects the host, user, and key used for remote authentication.

| Setting | File | Used for |
| --- | --- | --- |
| Commit identity | `~/.gitconfig` | Creating commits |
| Host and key selection | `~/.ssh/config` | Fetching and pushing over SSH |

## Git identity

Set a default identity, then use `includeIf` for repositories that need a different one. These are example identities and paths.

```ini
# ~/.gitconfig
[core]
    excludesfile = ~/.gitignore_global

[alias]
    st = status
    cm = commit
    co = checkout

[user]
    name = Alex
    email = alex@example.com

# Optional on macOS: credentials for HTTPS remotes.
[credential]
    helper = osxkeychain

[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

```ini
# ~/.gitconfig-work
[user]
    name = Alex Work
    email = alex.work@example.com
```

Run these inside a repository to see its effective identity:

```sh
git config user.name
git config user.email
```

A different commit identity does not change which account authenticates to the remote.

## SSH keys

A typical SSH directory contains:

```text
~/.ssh/
  config          host and key selection
  id_ed25519      private key
  id_ed25519.pub  public key registered with the service
  known_hosts     fingerprints of previously contacted servers
```

Example configuration for GitHub over port 443 and a separate GitLab server:

```sshconfig
Host github.com
    HostName ssh.github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host gitlab.example.com
    HostName gitlab.example.com
    Port 22
    User git
    IdentityFile ~/.ssh/id_rsa
    IdentitiesOnly yes
```

GitHub's port 443 endpoint is `ssh.github.com`. See the [official GitHub instructions](https://docs.github.com/en/authentication/troubleshooting-ssh/using-ssh-over-the-https-port).

| Field | Meaning |
| --- | --- |
| `Host` | Alias matched against the host in your command or remote URL |
| `HostName` | Server address to connect to |
| `Port` | SSH port; normally 22 |
| `User` | Login user required by the server; these examples use `git` |
| `IdentityFile` | Private key whose public key is registered with the service |
| `IdentitiesOnly` | Limits authentication identities to those configured |

Test the matching configuration:

```sh
ssh -T git@github.com
ssh -T git@gitlab.example.com
```

For a commit identity problem, inspect Git config. For an authentication problem, inspect the remote URL, SSH config, and registered public key.
