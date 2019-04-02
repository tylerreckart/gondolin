# ==============================================================================
# Gondolin Prompt Theme
# Copyright (c) 2018-2019 Tyler Reckart <tyler.reckart@gmail.com>
#
# To use this theme, first install via epm:
# use epm
# epm:install github.com/tylerreckart/gondolin
#
# Then add the following line to your ~/.elvish/rc.elv file:
# use github.com/tylerreckart/gondolin/gondolin
# ==============================================================================

use epm
use re

# -----------------------------------------------------------------------------
# Generate Aliases
# -----------------------------------------------------------------------------

# [TODO] aliases go here

# -----------------------------------------------------------------------------
# Completion Utilities
# -----------------------------------------------------------------------------

# case-insensitive smart completion
# edit:completion:matcher[''] = [p]{ edit:match-prefix &smart-case $p }

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

fn even [int]{
  put ($int % 2)
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

git-index = (joins ' ' [(put (git status --porcelain -b 2> /dev/null))])

fn has-git-index-updated {
  current-index = (joins ' ' [(put (git status --porcelain -b 2> /dev/null))])

  if (not (is $git-index $current-index)) {
    put $true
  } else {
    put $false
  }
}

fn generate-status-string {
  status = ''

  # use a regex to search for each possible status character combination in the git index
  # if a match is found, append the appropriate status to the status string
  if (re:match '\?\?\s+' $git-index) {
    status = $status'git-prompt-untracked,'
  }

  a-1 = (re:match 'A\s' $git-index)
  a-2 = (re:match '\sM\s\s' $git-index)

  if (or $a-1 $a-2) {
    status = $status'git-prompt-added,'
  }

  m-1 = (re:match '\sM\s' $git-index)
  m-2 = (re:match '\sMM\s' $git-index)
  m-3 = (re:match '\sAM\s' $git-index)
  m-4 = (re:match '\sT\s' $git-index)

  if (or $m-1 $m-2 $m-3 $m-4) {
    status = $status'git-prompt-modified,'
  }

  if (re:match '\sR\s' $git-index) {
    status = $status'git-prompt-renamed,'
  }

  d-1 = (re:match '\sD\s' $git-index)
  d-2 = (re:match '\sD\s\s' $git-index)
  d-3 = (re:match '\sAD\s' $git-index)

  if (or $d-1 $d-2 $d-3) {
    status = $status'git-prompt-deleted,'
  }

  if (re:match '\sUU\s' $git-index) {
    status = $status'git-prompt-unmerged,'
  }

  if (re:match '##\s.*ahead' $git-index) {
    status = $status'git-prompt-ahead,'
  }

  if (re:match '##\s.*behind' $git-index) {
    status = $status'git-prompt-behind,'
  }

  if (re:match '##\s.*diverged' $git-index) {
    status = $status'git-prompt-diverged,'
  }

  put (assoc [(re:split '[,]' $status)] -1 'empty')
}

fn git-status {
  status = (generate-status-string)

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
    &empty=                ' '
  ]

  for x $status {
    glyph = $status-glyphs[$x]
    # use a regex to match each possible status
    # if a match is found, output a colorized glyph to the readline
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
      edit:styled ' '$glyph lightblue
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

prompt-pwd-dir-length = 1

fn prompt-pwd {
  tmp = (tilde-abbr $pwd)
  if (== $prompt-pwd-dir-length 0) {
    put $tmp
  } else {
    re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
  }
}

edit:prompt = {
  # the current working directory
  edit:styled (prompt-pwd) lightblue

  put ' '

  # only execute if the current directory is a git repository
  if (not (has_failed { branch })) {
    # current branch indicator
    edit:styled '⎇ ' green
    edit:styled (branch) green

    # current branch status readout
    status-string = (echo (git-status))
    # only print to readline if there is a status
    if (> (count $status-string) 0) {
      put (git-status)
    }

    put ' '

    # print first 8 chars of current commit hash
    edit:styled (put (commit_id)[:8]) white

    put ' '

    # display time since the last commit was made in the
    # current working directory
    put (git-time-since-commit)
  }

  put "\n"

  edit:styled "→ " white
}

edit:rprompt = { }
# Set a max amount of time in seconds that the prompt will wait for
# a the execution of the prompt. If the prompt takes longer than this
# set amoutn of time, display it will display the last value of the
# prompt with a stale marker (?). When the prompt finishes execution,
# the marker will be removed and the prompt will be updated.
edit:-prompts-max-wait = 0.05
