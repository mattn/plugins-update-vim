function! s:vcsUpdate(path, commands)
  let path = substitute(a:path, '[\\/].\?$', '', 'g')
  let sep = !exists("+shellslash") || &shellslash ? '/' : '\'
  if &shellslash
    let command = printf('cd ''%s'' && %s', path, join(a:commands, ' && '))
  else
    let command = printf('cmd /c "cd %s & %s"', path, join(a:commands, ' & '))
  endif
  let message = printf("updating %s", strpart(path, strridx(path, sep)+1))
  echo message
  call setline(line('$'), [message, ""])
  redraw
  call setline(line('$'), map(split(system(command), "\n"), '"  ".v:val'))
  redraw
  normal! G
endfunction

function! s:isUpdatableGit(path)
  let sep = !exists("+shellslash") || &shellslash ? '/' : '\'
  if &shellslash
    let command = printf('cd ''%s'' && git branch', a:path)
  else
    let command = printf('cmd /c "cd %s & git branch"', a:path)
  endif
  let master = filter(split(system(command), "\n"), 'v:val[0] == "*"')
  if len(master) == 1
    return master[0][2:] == "master"
  endif
  return 0
endfunction

function! s:PluginsUpdate()
  silent new __PLUGINS_UPDATE__
  setlocal buftype=nofile
  redraw
  let vcs = [
  \ {"meta": ".git", "cmd": "git", "update": ["git pull --rebase origin master"], "check": function('s:isUpdatableGit') },
  \ {"meta": ".hg",  "cmd": "hg",  "update": ["hg pull", "hg update"]                                     },
  \ {"meta": ".svn", "cmd": "svn", "update": ["svn update"]                                               },
  \]
  for path in map(split(&rtp, ','), 'fnamemodify(v:val, ":p")')
    for v in vcs
      if executable(v.cmd) && isdirectory(printf("%s/%s", path, v.meta))
        if has_key(v, 'check')
          if !s:isUpdatableGit(path)
            break
          endif
        endif
        call s:vcsUpdate(path, v.update)
        break
      endif
    endfor
  endfor
endfunction

command! PluginsUpdate :call <SID>PluginsUpdate()
