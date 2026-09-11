# Shell notes

## Variables

| Variable | Meaning |
| --- | --- |
| `$0` | Script invocation name or path; in an interactive shell, the shell name |
| `$HOME` | Current user's home directory |

## Paths and command substitution

`dirname` removes the final component of a path. It operates on the path string, without checking whether it exists.

```sh
dirname /projects/demo/install.sh
# /projects/demo
```

`$(...)` runs a command and substitutes its output. Quote it when the result might contain spaces:

```sh
cd "$(dirname /projects/demo/install.sh)"
```

## Command operators

| Operator | Behavior | Example |
| --- | --- | --- |
| `&&` | Run the next command after success | `mkdir demo && cd demo` |
| `&` | Start a command in the background | `sleep 10 & echo ready` |
| `||` | Run the next command after failure | `cd demo || echo missing` |
| `;` | Run commands sequentially regardless of success | `cd demo; pwd` |

In Bash/Zsh, `cd demo & pwd` leaves the foreground shell in its original directory. `cd demo && pwd` changes that shell's directory after a successful `cd`.

## Error handling

```sh
set -euo pipefail
```

| Option | Effect |
| --- | --- |
| `-e` | Exit on many unhandled command failures; conditional lists and other contexts have exceptions |
| `-u` | Treat expansion of unset variables as an error |
| `pipefail` | Make a pipeline fail when one of its commands fails |

These options help propagate errors. Commands used as conditions still need explicit handling where appropriate.
