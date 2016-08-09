let s:sep = !exists("+shellslash") || &shellslash ? '/' : '\'

function! s:vcsUpdate(path, commands)
  let path = substitute(a:path, '[\\/].\?$', '', 'g')
  if s:sep == '/'
    let command = printf('cd ''%s'' && %s', path, join(a:commands, ' && '))
  else
    let command = printf('cmd /c "cd %s & %s"', path, join(a:commands, ' & '))
  endif
  let message = printf("updating %s", strpart(path, strridx(path, s:sep)+1))
  echo message
  call setline(line('$'), [message, ""])
  redraw
  call setline(line('$'), map(split(system(command), "\n"), '"  ".v:val'))
  redraw
  normal! G
endfunction

function! s:isUpdatableGit(path)
  if s:sep == '/'
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
  if exists('*Unbundle')
    call Unbundle('ftbundle/*/*')
  endif
  for path in map(split(&rtp, ','), 'fnamemodify(v:val, ":p:gs?/$??")')
    for v in vcs
      if executable(v.cmd) && isdirectory(printf("%s/%s", path, v.meta))
        if has_key(v, 'check')
          if !v.check(path)
            break
          endif
        endif
        call s:vcsUpdate(path, v.update)
      endif
    endfor
  endfor
endfunction

command! PluginsUpdate :call <SID>PluginsUpdate()
