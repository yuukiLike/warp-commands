# GitHub SSH

Generate a key with your own email or label:

```sh
ssh-keygen -t ed25519 -C "you@example.com"
```

Keep the private key on your computer. Add the contents of the public key to GitHub under **Settings > SSH and GPG keys**:

```sh
cat ~/.ssh/id_ed25519.pub
```

On macOS, copy the public key directly:

```sh
pbcopy < ~/.ssh/id_ed25519.pub
```

Test authentication and inspect the repository remote:

```sh
ssh -T git@github.com
git remote -v
```

To use SSH for a repository, replace `OWNER` and `REPO`:

```sh
git remote set-url origin git@github.com:OWNER/REPO.git
```

GitHub verifies signatures made with your private key against the public key registered to your account. The private key stays on your machine. If the key has a passphrase, an SSH agent can remember it for convenience.

See GitHub's guides to [testing SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection) and [adding a key to ssh-agent](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
