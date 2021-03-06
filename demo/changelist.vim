" Think :changes could be a bit sexier?
"
" Use   <leader>g;   or   :Changes   to enter the changelist overlay

" In the overlay window:
" You're prompted with a filter pattern. Use <esc> to cancel.
" <enter> jumps to the current entry
" q closes the overlay without action

function! ChangeListData()
  let data = reverse(vimple#redir('changes')[1:])
  let files = {}
  let lines = []
  for d in data
    if d == '>'
      call add(lines, "x 0\t<-- At changelist head")
      continue
    endif
    let [n, l, c; t] = split(matchstr(d, '^>\?\zs.*'), '\s\+')
    let tt = join(t, ' ')
    let type = 'l'
    if (tt != '') && (filereadable(tt) || (bufnr(tt) != -1))
      let type = 'f'
      if has_key(files, tt)
        continue
      endif
      let files[tt] = 1
    endif
    call add(lines, join([type, n, l], ' ') . "\t" . tt)
  endfor
  return lines
endfunction

function! ChangeList()
  call overlay#show(
        \  ChangeListData()
        \, {
        \    '<enter>' : ':call ChangeListAccept()<cr>'
        \  , 'q' : ':call overlay#close()<cr>'
        \  }
        \, {'filter'    : 0, 'use_split' : 1})
  call search('^.\s*0', 'w')
  set syntax=vimple_jumplist
  setlocal conceallevel=2 concealcursor=nv tabstop=12
endfunction

function! ChangeListAccept()
  let l   = line('.')
  let cur = search('^.\s*0', 'wn')
  if l == cur
    call overlay#close()
    return
  else
    let lst = overlay#select_buffer()
    let num = matchstr(lst[l-1], '\d\+')
    let dir = (l > cur) ? "g;" : "g,"
    exe 'silent! norm! ' . num . dir
  endif
endfunction

nnoremap <leader>g; :call ChangeList()<cr>
nnoremap <leader>g, :call ChangeList()<cr>
command! -nargs=0 Changes call ChangeList()
