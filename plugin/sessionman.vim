"============================================================================"
"
"  Vim session manager
"
"  Copyright (c) Yuri Klubakov
"
"  Author:      Yuri Klubakov <yuri.mlists at gmail dot com>
"  Version:     1.0 (2007-09-02)
"  Requires:    Vim 6
"  License:     GPL
"
"  Description:
"
"  Vim provides a ':mksession' command to save the current editing session.
"  This plug-in helps to work with Vim sessions by keeping them in the
"  deticated location and by providing commands to save session, list all
"  sessions, open last session and close session.  From a list of sessions
"  you can open session and delete session.
"
"  Sessions are saved in the "$HOME/sessions" directory or in the
"  "$VIM/sessions" directory if $HOME is not defined.  If this directory does
"  not exist, it will be created by the :SaveSession command.
"
"  :ListSessions command opens a buffer with session names.
"  Status line shows normal mode mappings:
"    <ESC> or 'q' - wipe the buffer
"    <CR> or <2-LeftMouse> or 'o' - open session
"    'd' - delete session
"  The name of an opened session is saved in g:LAST_SESSION variable which is
"  saved in the viminfo file if 'viminfo' option contains '!'.  It is used to
"  open last session by :OpenLastSession command.  It can be done when Vim
"  starts (gvim +bd -c OpenLastSession) or any time during a Vim session.
"  When session is opened and 'cscope' is enabled, script calls 'cscope add'
"  for the current directory so make sure it is set correctly for the session.
"
"  :CloseSession command wipes out all buffers, kills cscope and clears
"  variables with session name.
"
"  :SaveSession command asks for a session name (default is the last part of
"  v:this_session) and saves the current editing session using :mksission
"  command.
"
"  :OpenLastSession command opens a g:LAST_SESSION session (see above).
"
"============================================================================"

if !has('mksession') || exists('loaded_sessionmanager')
	finish
endif
let loaded_sessionmanager = 1

let s:save_cpo = &cpo
set cpo&vim

let s:sessions_path = (($HOME != '') ? $HOME : $VIM) . '/sessions/'

"============================================================================"

function! s:OpenSession(name)
	let g:LAST_SESSION = a:name
	execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
	let n = bufnr('%')
	execute 'silent! so ' . s:sessions_path . a:name
	execute 'silent! bwipeout! ' . n
	if has('cscope')
		silent! cscope kill -1
		silent! cscope add .
	endif
endfunction

"============================================================================"

function! s:CloseSession()
	execute 'silent! 1,' . bufnr('$') . 'bwipeout!'
	silent! cscope kill -1
	unlet! g:LAST_SESSION
	let v:this_session = ''
endfunction

"============================================================================"

function! s:DeleteSession(name)
	let name = getline('.')
	if name != ''
		let save_go = &guioptions
		set guioptions+=c
		if confirm('Are you sure you want to delete "' . name . '" session?', "&Yes\n&No", 2) == 1
			setlocal modifiable
			d
			setlocal nomodifiable
			if delete(s:sessions_path . name) != 0
				redraw | echohl ErrorMsg | echo 'Error deleting "' . name . '" session file' | echohl None
			endif
		endif
		let &guioptions = save_go
	endif
endfunction

"============================================================================"

function! s:Quit()
	execute s:b_cur . 'b'
endfunction

"============================================================================"

function! s:ListSessions()
	let s:b_cur = winbufnr(0)
	silent! edit __Sessions__

	" Mark the buffer as scratch
	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted

	nnoremap <buffer> <silent> <ESC> :call <SID>Quit()<CR>
	nnoremap <buffer> <silent> q :call <SID>Quit()<CR>
	nnoremap <buffer> <silent> o :call <SID>OpenSession(getline('.'))<CR>
	nnoremap <buffer> <silent> <CR> :call <SID>OpenSession(getline('.'))<CR>
	nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>OpenSession(getline('.'))<CR>
	nnoremap <buffer> <silent> d :call <SID>DeleteSession(getline('.'))<CR>

	let sessions = substitute(glob(s:sessions_path . '*'), '\\', '/', 'g')
	let sessions = substitute(sessions, '.\{-}/sessions/\(.\{-}\(\n\|$\)\)', '\1', 'g')
	if sessions == ''
		redraw | echohl ErrorMsg | echo 'There are no saved sessions' | echohl None
		return
	endif

	silent! put =sessions
	silent! 0,1d
	redraw | echo "<ESC> or 'q' - close, <CR> or <2-LeftMouse> or 'o' - open, 'd' - delete"
	setlocal nomodifiable
endfunction

"============================================================================"

function! s:SaveSession()
	let name = substitute(v:this_session, '.*\(/\|\\\)', '', '')
	let s = input('Save session as: ', name)
	if s != ''
		if finddir('sessions', escape(($HOME != '') ? $HOME : $VIM, ' ')) == ''
			call mkdir(s:sessions_path)
		endif
		silent! argdel *
		let v:this_session = s:sessions_path . s
		execute 'silent mksession! ' . v:this_session
	endif
endfunction

"============================================================================"

command! -nargs=0 OpenLastSession if exists('g:LAST_SESSION') | call s:OpenSession(g:LAST_SESSION) | endif
command! -nargs=0 CloseSession call s:CloseSession()
command! -nargs=0 ListSessions call s:ListSessions()
command! -nargs=0 SaveSession call s:SaveSession()

let &cpo = s:save_cpo

" vim: set ts=4 sw=4 noet :
