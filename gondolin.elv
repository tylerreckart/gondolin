# ==============================================================================
# Gondolin
# ==============================================================================

use epm
use re

# -----------------------------------------------------------------------------
# Generate Aliases
# -----------------------------------------------------------------------------

# case-insensitive smart completion
edit:completion:matcher[''] = [p]{ edit:match-prefix &smart-case $p }

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

fn even [int]{
  put ($int % 2)
}

fn require [pkg]{
  use epm
  if (epm:is-installed $pkg) {
    epm:upgrade $pkg
  } else {
    epm:install &silent-if-installed=$true $pkg
  }
}

fn floor [x]{
  @r = (splits . $x)
  put $r[0]
}

fn map [f @rest]{
  a = (optional_in $rest)

  @res = (for x $a {
    put ($f $x)
  })

  put $res
}

fn now {
  put (date +%s)
}

fn optional_in [rest]{
  arr = []

  if (not (eq (count $rest) 1)) {
    arr = (all)
  } else {
    arr = $rest[0]
  }

  put $arr
}

# -----------------------------------------------------------------------------
# Git Functions
# -----------------------------------------------------------------------------

# utility functions
fn null_out [f]{
  { $f 2>&- > /dev/null }
}

fn has_failed [p]{
  eq (bool ?(null_out $p)) $false
}

# repo status functions
fn branch {
  put (git rev-parse --abbrev-ref HEAD)
}

fn commit_id {
  put (git rev-parse HEAD)
}

fn generate-git-timestamp [a b]{
  put (- $a $b)
}

fn is_dirty {
  has_failed { git diff-index --quiet HEAD }
}

fn last-commit {
  put (git log -1 --pretty=format:%ct)
}

fn not-stale {
  put (git status -s 2> /dev/null)
}

fn status {
  put (git status -s 2> /dev/null)
}

fn git-status {
  index = (joins ' ' [(put (git status --porcelain -b 2> /dev/null))])
  status = ''

  # untracked
  if (re:match '\?\?\s+' $index) {
    status = '&git-prompt-untracked'$status
  }
  # added
  if (re:match 'A\s' $index) {
    status = '&git-prompt-added'$status
  } elif (re:match '\sM\s\s' $index) {
    status = '&git-prompt-added'$status
  }
  # modified
  if (re:match '\sM\s\w' $index) {
    status = '&git-prompt-modified'$status
  } elif (re:match '\sMM\s' $index) {
    status = '&git-prompt-modified'$status
  } elif (re:match '\sAM\s' $index) {
    status = '&git-prompt-modified'$status
  } elif (re:match '\sT\s' $index) {
    status = '&git-prompt-modified'$status
  }
  # renamed
  if (re:match '\sR\s' $index) {
    status = '&git-prompt-renamed'$status
  }
  # deleted
  if (re:match '\sD\s' $index) {
    status = '&git-prompt-deleted'$status
  } elif (re:match '\sD\s\s' $index) {
    status = '&git-prompt-deleted'$status
  } elif (re:match '\sAD\s' $index) {
    status = '&git-prompt-deleted'$status
  }
  # unmerged
  if (re:match '\sUU\s' $index) {
    status = '&git-prompt-unmerged'$status
  }
  # ahead
  if (re:match '##\s.*ahead' $index) {
    status = '&git-prompt-ahead'$status
  }
  # behind
  if (re:match '##\s.*behind' $index) {
    status = '&git-prompt-behind'$status
  }
  # diverged
  if (re:match '##\s.*diverged' $index) {
    status = '&git-prompt-diverged'$status
  }

  last-status = [(drop 1 [(re:split '[&]' $status)])]

  status-glyphs = [
    &git-prompt-untracked= '?'
    &git-prompt-added=     '!'
    &git-prompt-modified=  '+'
    &git-prompt-renamed=   '»'
    &git-prompt-deleted=   '✘'
    &git-prompt-unmerged=  '§'
    &git-prompt-ahead=     '⇡'
    &git-prompt-behind=    '⇣'
    &git-prompt-diverged=  '⇕'
  ]

  for x $last-status {
    glyph = $status-glyphs[$x]

    if (re:match 'git-prompt-untracked' $x) {
      edit:styled ' '$glyph magenta
    }

    if (re:match 'git-prompt-added' $x) {
      edit:styled ' '$glyph lightblue
    }

    if (re:match 'git-prompt-modified' $x) {
      edit:styled ' '$glyph yellow
    }

    if (re:match 'git-prompt-renamed' $x) {
      edit:styled ' '$glyph green
    }

    if (re:match 'git-prompt-deleted' $x) {
      edit:styled ' '$glyph red
    }

    if (re:match 'git-prompt-unmerged' $x) {
      edit:styled ' '$glyph lightblue
    }

    if (re:match 'git-prompt-ahead' $x) {
      edit:styled ' '$glyph blue
    }

    if (re:match 'git-prompt-behind' $x) {
      edit:styled ' '$glyph red
    }

    if (re:match 'git-prompt-diverged' $x) {
      edit:styled ' '$glyph yellow
    }
  }
}

fn git-time-since-commit {
  last-commit = (last-commit)
  now = (now)

  seconds-since-last-commit = (generate-git-timestamp $now $last-commit)
  minutes-since-last-commit = (floor (/ $seconds-since-last-commit 60))
  hours-since-last-commit = (floor (/ $seconds-since-last-commit 3600))
  days-since-last-commit = (floor (/ $seconds-since-last-commit 86400))

  sub-hours = (% $hours-since-last-commit 24)
  sub-minutes = (% $minutes-since-last-commit 60)

  commit-age = ''

  if (> $hours-since-last-commit 24) {
    commit-age = $days-since-last-commit"d"
  } elif (> $minutes-since-last-commit 60) {
    commit-age = $sub-hours"h"$sub-minutes"m"
  } else {
    commit-age = $minutes-since-last-commit"m"
  }

  if (is (status) $true) {
    if (> $hours-since-last-commit 4) {
      edit:styled $commit-age red
    } elif (> $minutes-since-last-commit 30) {
      edit:styled $commit-age yellow
    } else {
      edit:styled $commit-age green
    }
  } else {
    edit:styled $commit-age white
  }

  if (is_dirty) {
    edit:styled ' ✗' red
  }
}

# -----------------------------------------------------------------------------
# Prompt Configuration
# -----------------------------------------------------------------------------

edit:prompt = {
  edit:styled (tilde-abbr $pwd) lightblue

  put ' '

  if (not (has_failed { branch })) {
    edit:styled '⎇ ' green
    edit:styled (branch) green

    status-string = (echo (git-status))

    if (> (count $status-string) 0) {
      put (git-status)
    }

    put ' '

    edit:styled (put (commit_id)[:8]) white

    put ' '

    put (git-time-since-commit)
  }

  put "\n"

  edit:styled "→ " white
}

edit:rprompt = { }
