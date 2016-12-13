" Vim global plugin for synchronizing vim and evince with synctex
" Last Change:  2016 November 06
" Maintainer:   Peter B. Jørgensen <peterbjorgensen@gmail.com>
" License:  This file is licensed under the BEER-WARE license rev 42.
"   THE BEER-WARE LICENSE" (Revision 42):
"   <peterbjorgensen@gmail.com> wrote this file. 
"   As long as you retain this notice you can do whatever you want with this stuff.
"   If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

if exists("g:loaded_evinceSync")
	if g:loaded_evinceSync == 1
		finish
	endif
endif
let g:loaded_evinceSync = 1



" Get folder of current script using three steps:
"   1: Get the absolute path of the script
"   2: Resolve all symbolic links
"   3: Get the folder of the resolved absolute file
let s:spath = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:pycmd = s:spath . "/evinceSync.py"

function! SVED_OnExit(job, code)
	echom "evinceSynctex job quit with status " . a:code
	let g:loaded_evinceSync = 0
endfunction

let g:evinceSyncDaemonJob = job_start(["python3", s:pycmd], 
			\ {"exit_cb": "SVED_OnExit", "in_mode": "json", "out_mode": "json"})

function! SVED_Sync()
	let l:origdir = getcwd()

	"Get path of current file
	let l:curpath = expand('%:p:h')	
	if empty(l:curpath)
		let l:curpath = l:origdir
	endif
	execute "cd " . fnameescape(l:curpath)

	"Loop upwards from current path and search for .synctex.gz or .latexmain
	let l:stopdepth = 100
	let l:pdffile = ""
	let l:foundpdf = 0
	while getcwd() != "/" && l:stopdepth >= 0
		let l:matches = glob("*.latexmain", 0, 1)
		if !empty(l:matches)
			let l:pdffile = fnamemodify(l:matches[0],":p:r:r" ) . ".pdf"
			if filereadable(l:pdffile)
				let l:foundpdf = 1
				break
			endif
			let l:pdffile = fnamemodify(l:matches[0],":p:r" ) . ".pdf"
			if filereadable(l:pdffile)
				let l:foundpdf = 1
				break
			endif
		endif
		let l:matches = glob("*.synctex.gz", 0, 1)
		if !empty(l:matches)
			let l:pdffile = fnamemodify(l:matches[0],":p:r:r" ) . ".pdf"
			if filereadable(l:pdffile)
				let l:foundpdf = 1
				break
			endif
		endif

		cd ..
		let l:stopdepth -= 1
	endwhile
    execute "cd " . fnameescape(l:origdir)

	if !l:foundpdf
		echo "Did not find main pdf file"
		return
	endif


	let l:cursorpos = getcurpos()

	let l:command = "python3 " . shellescape(s:pycmd) . " " . shellescape(l:pdffile) . " " . 
				\ l:cursorpos[1] . " " . l:cursorpos[2] . " " . shellescape(expand("%:p"))
	let l:output = system(l:command)
	echo l:output
endfunction


