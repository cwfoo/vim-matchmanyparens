" matchmanyparens.vim
" Plugin for highlighting matching pairs that enclose the cursor.
" URL: https://github.com/cwfoo/vim-matchmanyparens

if exists('g:loaded_matchmanyparens')
    finish
endif
let g:loaded_matchmanyparens = 1

let s:save_cpo = &cpo
set cpo&vim

" Global settings.
if !exists('g:matchmanyparens_pairs')
    let g:matchmanyparens_pairs = [['(', ')'], ['[', ']'], ['{', '}']]
endif

if !exists('g:matchmanyparens_max_pairs')
    let g:matchmanyparens_max_pairs = 20
endif

if !exists('g:matchmanyparens_extra_matchlines')
    let g:matchmanyparens_extra_matchlines = 10
endif

if !exists('g:matchmanyparens_timeout')
    let g:matchmanyparens_timeout = 200
endif

if !exists('g:matchmanyparens_noncode_enable')
    let g:matchmanyparens_noncode_enable = 1
endif

if !exists('g:matchmanyparens_noncode_pairs')
    let g:matchmanyparens_noncode_pairs = [['(', ')'], ['[', ']'], ['{', '}']]
endif

if !exists('g:matchmanyparens_disabled_filetypes')
    let g:matchmanyparens_disabled_filetypes = []
endif

if !exists('g:matchmanyparens_filetype_settings')
    let g:matchmanyparens_filetype_settings = {}
endif

if !exists('g:matchmanyparens_highlight_groups')
    let g:matchmanyparens_highlight_groups = [
        \'MatchParens0',
        \'MatchParens1',
        \'MatchParens2',
        \'MatchParens3',
        \'MatchParens4',
        \'MatchParens5',
        \'MatchParens6',
        \'MatchParens7',
        \'MatchParens8',
        \'MatchParens9',
    \]
endif

" Default highlight groups.
" By default, MatchParens0 is for the innermost pair.
highlight default MatchParens0 cterm=NONE ctermbg=lightgreen   ctermfg=black
                               \ gui=NONE   guibg=lightgreen     guifg=black
highlight default MatchParens1 cterm=NONE ctermbg=brown        ctermfg=white
                               \ gui=NONE   guibg=brown          guifg=white
highlight default MatchParens2 cterm=NONE ctermbg=blue         ctermfg=white
                               \ gui=NONE   guibg=blue           guifg=white
highlight default MatchParens3 cterm=NONE ctermbg=lightred     ctermfg=black
                               \ gui=NONE   guibg=lightred       guifg=black
highlight default MatchParens4 cterm=NONE ctermbg=grey         ctermfg=black
                               \ gui=NONE   guibg=grey           guifg=black
highlight default MatchParens5 cterm=NONE ctermbg=lightblue    ctermfg=black
                               \ gui=NONE   guibg=lightblue      guifg=black
highlight default MatchParens6 cterm=NONE ctermbg=lightmagenta ctermfg=black
                               \ gui=NONE   guibg=lightmagenta   guifg=black
highlight default MatchParens7 cterm=NONE ctermbg=green        ctermfg=black
                               \ gui=NONE   guibg=green          guifg=black
highlight default MatchParens8 cterm=NONE ctermbg=yellow       ctermfg=black
                               \ gui=NONE   guibg=yellow         guifg=black
highlight default MatchParens9 cterm=NONE ctermbg=lightcyan    ctermfg=black
                               \ gui=NONE   guibg=lightcyan      guifg=black

" For the pair in a string or comment.
highlight default MatchParensNonCode cterm=NONE ctermbg=cyan ctermfg=black
                                     \ gui=NONE   guibg=cyan   guifg=black

function! s:initialize()
    if index(g:matchmanyparens_disabled_filetypes, &filetype) >= 0
        return
    endif
    augroup matchmanyparens
        autocmd! CursorMoved,CursorMovedI <buffer> call s:highlight_pairs()
        " TextChanged,TextChangedI — e.g. needed when indenting using >>.
        " TextChangedP — needed when text is inserted when a completion menu
        " is shown.
        autocmd! TextChanged,TextChangedI,TextChangedP <buffer> call s:highlight_pairs()
    augroup END
endfunction

augroup matchmanyparens
    autocmd! BufEnter * call s:initialize()
augroup END

" Return 1 if the syntax group of the character under the cursor matches the
" given pattern. Return 0 otherwise.
function! s:is_in_syntax(pattern)
    for syn_id in synstack(line('.'), col('.'))
        if synIDattr(syn_id, 'name') =~? a:pattern
            return 1
        endif
    endfor
    return 0
endfunction

let s:string_pattern = 'string\|character\|singlequote\|escape'
let s:comment_pattern = 'comment'

" Return 1 if the cursor is in a string. Return 0 otherwise.
function! s:is_in_string()
    return s:is_in_syntax(s:string_pattern)
endfunction

" Return 1 if the cursor is in a comment. Return 0 otherwise.
function! s:is_in_comment()
    return s:is_in_syntax(s:comment_pattern)
endfunction

" Return 1 if the cursor is in a string or comment. Return 0 otherwise.
function! s:is_in_string_or_comment()
    return s:is_in_syntax(s:string_pattern . '\|' . s:comment_pattern)
endfunction

" Get the character under the cursor. Handles multibyte characters correctly.
function! s:get_current_char()
    return nr2char(strgetchar(getline(line('.'))[col('.') - 1], 0))
endfunction

" Similar to searchpairpos(), but escapes characters that have special
" meaning in regex.
function! s:searchpairpos_escaped(open_char, mid, close_char,
                                 \flags, skip, stopline)
    let open_char = escape(a:open_char, '[]\')  " Escape for regex.
    let close_char = escape(a:close_char, '[]\')
    return searchpairpos(open_char, a:mid, close_char,
                        \a:flags, a:skip, a:stopline,
                        \g:matchmanyparens_timeout)
endfunction

function! s:remove_all_highlighting()
    for id in w:matchmanyparens_highlight_ids
        call matchdelete(id)
    endfor
    let w:matchmanyparens_highlight_ids = []
endfunction

" From the current cursor position, find the position of the innermost pair (in
" code). The search is bounded above by stoplinetop, and bounded below by
" stoplinebottom.
" Return [[0, 0], [0, 0]] if not found.
function! s:find_first_code_pair(pairs, stoplinetop, stoplinebottom)
    let pos_open = [0, 0]
    let pos_close = [0, 0]

    let stoplinetop = a:stoplinetop
    let stoplinebottom = a:stoplinebottom

    let current_char = s:get_current_char()

    for [open_char, close_char] in a:pairs
        " Get the position of the opening character.
        if current_char ==# open_char && !s:is_in_string_or_comment()
            let match_open = [line('.'), col('.')]
        else
            let match_open = s:searchpairpos_escaped(
                    \open_char, '', close_char,
                    \'Wnb', 's:is_in_string_or_comment()',
                    \stoplinetop)
        endif

        if match_open[0] > pos_open[0] ||
                \(match_open[0] == pos_open[0] && match_open[1] > pos_open[1])
            " Get the position of the closing character.
            if current_char ==# close_char && !s:is_in_string_or_comment()
                let match_close = [line('.'), col('.')]
            else
                let match_close = s:searchpairpos_escaped(
                        \open_char, '', close_char,
                        \'Wn', 's:is_in_string_or_comment()',
                        \stoplinebottom)
            endif

            if match_close != [0, 0]
                let pos_open = match_open
                let pos_close = match_close
                let stoplinetop = match_open[0]
                let stoplinebottom = match_close[0]
            endif
        endif
    endfor

    return [pos_open, pos_close]
endfunction

" Return 1 if the current position is enclosed by the given code pair.
" Return 0 otherwise.
function! s:is_enclosed_by_code_pair(code_pairs, open_pos, close_pos,
                                    \stoplinetop, stoplinebottom)
    let code_pair_pos = s:find_first_code_pair(
            \a:code_pairs,
            \a:open_pos[0] > 0 ? a:open_pos[0] : a:stoplinetop,
            \a:close_pos[0] > 0 ? a:close_pos[0] : a:stoplinebottom)
    return code_pair_pos == [a:open_pos, a:close_pos]
endfunction

" Find the position of the innermost pair in a string or comment.
" Return [[0, 0], [0, 0]] if not in a string or comment, or if a pair could
" not be found.
function! s:find_string_comment_pair(noncode_pairs, code_pairs,
                                    \code_open_pos, code_close_pos,
                                    \stoplinetop, stoplinebottom)
    if s:is_in_string()
        " Skip all non-strings and everything that is not at the same
        " parenthesis level as the current cursor position.
        let s_skip = '!s:is_in_string() || !s:is_enclosed_by_code_pair(' .
                \string(a:code_pairs) . ',' .
                \string(a:code_open_pos) . ',' .
                \string(a:code_close_pos) . ',' .
                \a:stoplinetop . ',' .
                \a:stoplinebottom . ')'
    elseif s:is_in_comment()
        let s_skip = '!s:is_in_comment() || !s:is_enclosed_by_code_pair(' .
                \string(a:code_pairs) . ',' .
                \string(a:code_open_pos) . ',' .
                \string(a:code_close_pos) . ',' .
                \a:stoplinetop . ',' .
                \a:stoplinebottom . ')'
    else
        return [[0, 0], [0, 0]]
    endif

    " Use an appropriate stopline.
    let code_open_line = a:code_open_pos[0]
    let code_close_line = a:code_close_pos[0]
    let stoplinetop = code_open_line > 0 ? code_open_line : a:stoplinetop
    let stoplinebottom = code_close_line > 0 ? code_close_line : a:stoplinebottom

    let pos_open = [0, 0]
    let pos_close = [0, 0]

    let current_char = s:get_current_char()

    for [open_char, close_char] in a:noncode_pairs
        " Get the position of the opening character.
        if current_char ==# open_char
            let match_open = [line('.'), col('.')]
        else
            let match_open = s:searchpairpos_escaped(
                    \open_char, '', close_char,
                    \'Wnb', s_skip,
                    \stoplinetop)
        endif

        if match_open[0] > pos_open[0] ||
                \(match_open[0] == pos_open[0] && match_open[1] > pos_open[1])
            " Get the position of the closing character.
            if current_char ==# close_char
                let match_close = [line('.'), col('.')]
            else
                let match_close = s:searchpairpos_escaped(
                        \open_char, '', close_char,
                        \'Wn', s_skip,
                        \stoplinebottom)
            endif

            if match_close != [0, 0]
                let pos_open = match_open
                let pos_close = match_close
                let stoplinetop = match_open[0]
                let stoplinebottom = match_close[0]
            endif
        endif
    endfor

    return [pos_open, pos_close]
endfunction

" Find the position of the innermost pair that encloses the given pair.
" Return [[0, 0], [0, 0]] if there is no such pair.
" Note: this function will move the cursor position without restoring
" the original cursor position!
function! s:find_next_code_pair(pairs, prev_open_pos, prev_close_pos,
                               \stoplinetop, stoplinebottom)
    let pos_open = [0, 0]
    let pos_close = [0, 0]

    let stoplinetop = a:stoplinetop
    let stoplinebottom = a:stoplinebottom

    for [open_char, close_char] in a:pairs
        call cursor(a:prev_open_pos)
        let match_open = s:searchpairpos_escaped(
                \open_char, '', close_char,
                \'Wnb', 's:is_in_string_or_comment()',
                \stoplinetop)

        if match_open[0] > pos_open[0] ||
                \(match_open[0] == pos_open[0] && match_open[1] > pos_open[1])
            call cursor(a:prev_close_pos)
            let match_close = s:searchpairpos_escaped(
                    \open_char, '', close_char,
                    \'Wn', 's:is_in_string_or_comment()',
                    \stoplinebottom)
            if match_close != [0, 0]
                let pos_open = match_open
                let pos_close = match_close
                let stoplinetop = match_open[0]
                let stoplinebottom = match_close[0]
            endif
        endif
    endfor

    return [pos_open, pos_close]
endfunction

function! s:highlight_pairs()
    silent! call s:remove_all_highlighting()

    " Get user settings.
    let ft_settings = get(g:matchmanyparens_filetype_settings, &filetype, {})
    let max_highlight_pairs = get(ft_settings, 'max_pairs',
            \g:matchmanyparens_max_pairs)
    let pairs = get(ft_settings, 'pairs', g:matchmanyparens_pairs)
    let offscreen_matchlines = get(ft_settings, 'extra_matchlines',
            \g:matchmanyparens_extra_matchlines)
    let highlight_groups = get(ft_settings, 'highlight_groups',
            \g:matchmanyparens_highlight_groups)
    let noncode_enable = get(ft_settings, 'noncode_enable',
            \g:matchmanyparens_noncode_enable)
    let noncode_pairs = get(ft_settings, 'noncode_pairs',
            \g:matchmanyparens_noncode_pairs)

    " Only look for opening and closing pairs within the visible window area
    " + some extra off-screen lines.
    let stoplinetop = line('w0') - offscreen_matchlines
    if stoplinetop < 1
        let stoplinetop = 1
    endif
    let last_line = line('$')
    let stoplinebottom = line('w$') + offscreen_matchlines
    if stoplinebottom > last_line
        let stoplinebottom = last_line
    endif

    " Find the first enclosing pair (in code, not in a string or comment).
    let [pos_open, pos_close] = s:find_first_code_pair(
            \pairs, stoplinetop, stoplinebottom)

    " If the cursor is in a string or comment, highlight one enclosing pair
    " in the string or comment.
    if noncode_enable
        let [noncode_open_pos, noncode_close_pos] = s:find_string_comment_pair(
                \noncode_pairs,
                \pairs,
                \pos_open, pos_close,
                \stoplinetop, stoplinebottom)
        if noncode_open_pos != [0, 0] && noncode_close_pos != [0, 0]
            call s:add_pair_highlight('MatchParensNonCode',
                                     \noncode_open_pos, noncode_close_pos)
        endif
    endif

    " Highlight the first enclosing pair.
    if pos_open == [0, 0] " || pos_close == [0, 0]
        return
    endif
    call s:add_pair_highlight(highlight_groups[0], pos_open, pos_close)

    " Highlight the other pairs.
    let save_pos = getpos('.')
    let highlight_groups_len = len(highlight_groups)
    let pair_count = 1
    while pair_count < max_highlight_pairs
        let [pos_open, pos_close] = s:find_next_code_pair(
                \pairs,
                \pos_open, pos_close,
                \stoplinetop, stoplinebottom)
        if pos_open == [0, 0] " || pos_close == [0, 0]
            break
        endif
        call s:add_pair_highlight(
                \highlight_groups[pair_count % highlight_groups_len],
                \pos_open, pos_close)
        let pair_count += 1
    endwhile
    call setpos('.', save_pos)  " Restore cursor position.
endfunction

" Highlight the given pair using the given highlight group.
function! s:add_pair_highlight(highlight_group, pos_open, pos_close)
    call add(w:matchmanyparens_highlight_ids,
            \matchaddpos(a:highlight_group, [a:pos_open, a:pos_close]))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
