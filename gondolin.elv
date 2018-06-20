# nvm
E:NVM_DIR = $E:HOME"/.nvm"
default_node = (cat $E:NVM_DIR"/alias/default")

# path
paths = [
  $E:HOME"/.cabal/bin"
  /snap/bin
  $E:HOME"/.bin"
  /usr/local/sbin
  /usr/local/bin
  /usr/sbin
  /usr/bin
  /sbin
  /bin
  $E:NVM_DIR"/versions/node/"$default_node"/bin"
]

git-glyphs = [
  &git-branch=    "⎇"
  &git-dirty=     "⊙"
  &git-ahead=     "⊕"
  &git-behind=    "∴"
  &git-staged=    "Ξ"
  &git-untracked= "⊖"
  &git-deleted=   "⊗"
  &arrow=         "~"
  &chain=         " "
]

use epm
use re

# utility functions
fn null_out [f]{
  { $f 2>&- > /dev/null }
}

fn has_failed [p]{
  eq (bool ?(null_out $p)) $false
}

fn to_list [@rest]{
  arr = []

  if (not (eq (count $rest) 1)) {
    @arr = (all)
  } else {
    arr = $rest[0]
  }

  put $arr
}

# git functions
fn branch {
  put (git rev-parse --abbrev-ref HEAD)
}

fn commit_id {
  put (git rev-parse HEAD)
}

fn is_dirty {
  has_failed { git diff-index --quiet HEAD }  
}

fn status {
  put (git status --porcelain) | to_list
}

edit:prompt = {  
  edit:styled "\n" white;
  edit:styled (tilde-abbr $pwd) lightblue;

  put ' ';

  if (not (has_failed { branch })) {
    edit:styled '⎇ ' green;
    edit:styled (branch) green;

    put ' ';

    edit:styled (put (commit_id)[:6]) yellow;

    put ' ';

    if (is_dirty) {
      edit:styled '✗' red;
    }
  }

  put "\n"

  edit:styled "> " white
}

edit:rprompt = { }

# case-insensitive smart completion
edit:-matcher[''] = [p]{ edit:match-prefix &smart-case $p }
