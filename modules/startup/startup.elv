fn configure-rc [source target]{
  if (and ?(test -f $target'.original') ?(test -f $target)) {
    return
  }

  if ?(test -L $target) {
    if (==s (readlink -f $target) $source) {
      return
    } else {
      unlink $target
    }
  } elif (and (not ?(test -f $target'.original')) ?(test -f $target)) {
    mv $target target'.original'
  } elif ?(test -f $target) {
    rm $target
  }

  ln -s $source $target
}

fn init {
  local:rc-files = [
    'bash_profile'
    'bashrc'
    'kshrc'
    'profile'
    'zlogout'
    'zprofile'
    'zshrc'
  ]

  local:home = (get-env HOME)

  for local:i $rc-files {
    configure-rc \
      $home'/.elvish/lib/github.com/tylerreckart/gondolin/modules/startup/rc'$i \
      $home'/.'$i
  }
}

init
