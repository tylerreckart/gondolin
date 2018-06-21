# Gondolin 
An delightfully-opinionated framework for managing your [Elvish](https://elv.sh) configuration.

Currently it shows:
* Clever hostname and username displaying.
* Prompt character turns red if the last command exits with non-zero code.
* Current Git branch and rich repo status **(WIP)**:
  * `?` — untracked changes;
  * `+` — uncommitted changes in the index;
  * `!` — unstaged changes;
  * `»` — renamed files;
  * `✘` — deleted files;
  * `$` — stashed changes;
  * `§` — unmerged changes;
  * `⇡` — ahead of remote branch;
  * `⇣` — behind of remote branch;
  * `⇕` — diverged changes.
* Current Git SHA

## Manifesto
Gondolin aims to provide the core infrastructure to allow you to install packages which extend or modify the look of your shell. It will be fast, extensible and easy to use.

## Installation
### Prerequisites 
_**Disclaimer:** Gondolin will work best on macOS and Linux._
  - Unix-like operating system
  - Elvish should be installed (v0.11 or newer, use `elvish --buildinfo` to confirm version). 
    - If Elvish is not installed, refer to the [installation guide](https://elv.sh/download/).
  - `git` should be installed

### Basic Installation
Gondolin can be installed and configured using the [Elvish Package Manager](https://elv.sh/ref/epm.html) (`epm`)
```sh
use epm

epm:install github.com/tylerreckart/gondolin

use github.com/tylerreckart/gondolin/gondolin
```

## Contributing
I'm far from an Elvish expert, and there are many ways that Gondolin can improve - if you have ideas on how to make the configuration easier to maintain (and faster), don't hesitate to file issues, fork, and send pull requests! 
