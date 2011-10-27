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
  let vcs = {
  \"git": { "meta": ".git", "cmd": "git", "update": ["git pull"] },
  \"hg" : { "meta": ".hg",  "cmd": "hg",  "update": ["hg pull", "hg update"] },
  \"svn": { "meta": ".svn", "cmd": "svn", "update": ["svn update"] },
  }
  for path in map(split(&rtp, ','), 'expand(v:val, ":p")')
    for v in keys(vcs)
      if executable(v.cmd) && isdirectory(printf("%s/%s", path, v.meta))
        call s:vcsUpdate(path, v.update)
        break
	endif
  endfor
endfunction

command! PluginsUpdate :call <SID>PluginsUpdate()
