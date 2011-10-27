function! s:vcsUpdate(path, commands)
  let sep = !exists("+shellslash") || &shellslash ? '/' : '\'
  if &shellslash
    let command = printf('cd ''%s'' && %s', a:path, join(a:commands, ' && '))
  else
    let command = printf('cmd /c "cd %s & %s"', a:path, join(a:commands, ' & '))
  endif
  call setline(line('$'), [printf("updating %s", strpart(a:path, strridx(a:path, sep)+1)), ""])
  redraw
  call setline(line('$'), map(split(system(command), "\n"), '"  ".v:val'))
  redraw
  normal! G
endfunction

function! s:PluginsUpdate()
  silent new __PLUGINS_UPDATE__
  setlocal buftype=nofile
  redraw
  for path in map(split(&rtp, ','), 'expand(v:val, ":p")')
    if isdirectory(printf("%s/.git", path))
      call s:vcsUpdate(path, ["git pull"])
    elseif isdirectory(printf("%s/.hg", path))
      call s:vcsUpdate(path, ["hg pull", "hg update"])
    elseif isdirectory(printf("%s/.svn", path))
      call s:vcsUpdate(path, ["svn update"])
    endif
  endfor
endfunction

command! PluginsUpdate :call <SID>PluginsUpdate()
