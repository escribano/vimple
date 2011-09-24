" BufferList object
" ARB
" version 0.8

function! SortByNumber(i1, i2)
  let i1 = str2nr(a:i1)
  let i2 = str2nr(a:i2)
  return i1 == i2 ? 0 : i1 > i2 ? 1 : -1
endfunction

function! BufferList()
  let bl = {}
  let bl.buffers = {}
  let bl.current = 0
  let bl.alternate = 0

  " public interface

  func bl.update() dict
    redir => bufliststr
    silent! ls
    redir END

    let buffers = {}

    let bufferlist = split(bufliststr, '\n')
    " Reorder and clean up a bit the output.
    for i in range(0, len(bufferlist) - 1)
      let bufferlist[i] = substitute(bufferlist[i], '^\s*\(\d\+\)\(\s*[-u%#ah=+x ]*\)\s\+\"\(.\{-}\)\"\s\+line\s\+\(\d\+\)\s*$', '\1,\2,\4,\3','')
    endfor

    " Split on commas.
    call map(bufferlist, 'split(v:val, ",")')
    " Restore file names with comma(s)
    call map(bufferlist, 'add(v:val[0:2], join(v:val[3:-1], ","))')
    " Empty names give an empty string instead of "[No Name]".
    call map(bufferlist,
          \ '{"number": v:val[0],'
          \.'"line": v:val[2],'
          \.'"name": (v:val[3]      =~ ''\[.\{-}\]'' ? bufname(v:val[0]) : v:val[3]),'
          \.'"listed": v:val[1]     !~ "u",'
          \.'"current": v:val[1]    =~ "%",'
          \.'"alternate": v:val[1]  =~ "#",'
          \.'"active": v:val[1]     =~ "a",'
          \.'"hidden": v:val[1]     =~ "h",'
          \.'"modifiable": v:val[1] !~ "-",'
          \.'"readonly": v:val[1]   =~ "=",'
          \.'"modified": v:val[1]   =~ "+",'
          \.'"read_error": v:val[1] =~ "x"}')

    for bfr in map(copy(bufferlist), '{v:val["number"]: v:val}')
      call extend(self.buffers, bfr)
    endfor

    let current_l = filter(copy(bufferlist), 'v:val["current"] == 1')
    let alternate_l = filter(copy(bufferlist), 'v:val["alternate"] == 1')
    let self.current = len(current_l) > 0 ?current_l[0].number : 0
    let self.alternate = len(alternate_l) > 0 ? alternate_l[0].number : 0
  endfun

  " to_s([format[, filter]])
  func bl.to_s(...) dict
    " An empty format argument uses the default.
    let s_format = a:0 && a:1 != '' ? a:1 : "%3b%f\"%n\" line %l\n"
    " Apply filter.
    let buffers = a:0 > 1 ? filter(copy(self.buffers), a:2) : self.buffers

    let args_d = {
          \ 'b': "buffers[key]['number']",
          \ 'f': "self.buffer_flags(buffers[key])",
          \ 'n': "buffers[key]['name']",
          \ 'l': "buffers[key]['line']"}
    let args = ''
    for item in map(split('x'.substitute(s_format, '%%', '', 'g'), '%'), 'matchstr(v:val, ''^[-+#. 0-9]*\zs.'')')
      let args .= get(args_d, item, '')
      let args .= args[-1] =~ ',' ? '' : ', '
    endfor
    let args = substitute(args, '^\s*,\s*\(.\{-}\),\s*$', '\1', '')

    let s_format = substitute(s_format, '\(%%\)*%[-0-9#+ .]*\zs[nfl]', 's', 'g')
    let s_format = substitute(s_format, '\(%%\)*%[-0-9#+ .]*\zsb', 'd', 'g')
    let printf_str ='printf("'.escape(s_format, '\"').'", '.args.')'

    let str = ''
    for key in sort(keys(buffers), 'SortByNumber')
      let str .= eval(printf_str)
    endfor
    return str
  endfunc

  " Private functions - don't need 'dict' modifier

  func bl.buffer_status(b)
    return a:b['active'] == 1 ? 'a' : a:b['hidden'] == 1 ? 'h' : '!'
  endfunc

  func bl.buffer_type(b)
    return a:b['current'] == 1 ? '%' : a:b['alternate'] == 1 ? '#' : ' '
  endfunc

  func bl.buffer_flags(b)
    return   (a:b['listed'] == 0 ? 'u' : ' ')
          \. (a:b['current'] == 1 ? '%' :
          \    (a:b['alternate'] == 1 ? '#' : ' '))
          \. (a:b['active'] == 1 ? 'a' :
          \    (a:b['hidden'] == 1 ? 'h' : ' '))
          \. (a:b['modifiable'] == 0 ? '-' :
          \    (a:b['readonly'] == 1 ? '=' : ' '))
          \. (a:b['modified'] == 1 ? '+' : ' ')
          \. (a:b['read_error'] == 1 ? 'x' : ' ')
  endfunc

  " constructor

  call bl.update()
  return bl
endfunction

let bl = BufferList()
call bl.update()      " not necessary here, just showing it's callable
"echo bl.buffers
"echo "Current buffer    : " . bl.current
"echo "Alternate buffer  : " . bl.alternate
"echo bl.buffers[1]
"echo "Buffer 1 is hidden: " . bl.buffers[1]['hidden']
echo bl.to_s()
echo bl.to_s("%b => \"%n\"\n", 'v:val.number =~ "[2-5]"')

" vim: et sw=2 ft=vim
