" svn 提交插件 by yangqing
" date@2017-12-29
" 使用说明：
" 直接调用Q_SvnStatus函数即可,在vimrc中增加如下配置:
" `command! Qsvn :call Q_SvnStatus()`
" 配置完成后输入:Qsvn
" ====================================
" 窗口中快捷键
" 按键o 加入提交列表
" 按键d 取消提交列表
" 按键s 提交列表中的文件
" 按键<F1> 显示帮助信息
" ************************
"
let s:brief_help = 1
let s:file_count = 0
if !exists('g:svn_async')
    let g:svn_async = 0
endif

if !exists('g:svn_ignore')
    let g:svn_ignore = 0
endif

function! s:Window_Toggle_Help_Text()
    let brief_help_size = 1
    let full_help_size = 12

    setlocal modifiable

    " Set report option to a huge value to prevent informational messages
    " while deleting the lines
    let old_report = &report
    set report=99999

    " Remove the currently highlighted tag. Otherwise, the help text
    " might be highlighted by mistake
    match none

    " Toggle between brief and full help text
    if s:brief_help
        let s:brief_help = 0
        " Remove the previous help
        exe '1,' . brief_help_size . ' delete _'
        " Adjust the start/end line numbers for the files
        call s:Window_Update_Line_Offsets(0, 1, full_help_size - brief_help_size)
    else
        let s:brief_help = 1
        " Remove the previous help
        exe '1,' . full_help_size . ' delete _'
        " Adjust the start/end line numbers for the files
        call s:Window_Update_Line_Offsets(0, 0, full_help_size - brief_help_size)
    endif

    call s:Window_Display_Help()

    " Restore the report option
    let &report = old_report

    setlocal nomodifiable
endfunction

function! s:Window_Display_Help()
    if s:brief_help
        call append(0, '" SVN 管理工具(1.0)  *查看帮助<F1>')
        call append(1, '" =============文件列表==============')
    else
        " Add the extensive help
        call append(0, '" SVN 管理工具(1.0)')
        call append(1, '" =============功能列表==============')
        call append(2, '" o/<enter> : 将文件加入到待提交列表')
        call append(3, '" x : 将文件从待提交列表中取消')
        call append(4, '" t : 在新标签打开文件')
        call append(5, '" r : 回滚文件[svn revert]')
        call append(6, '" d : 对比文件与版本库中的差异[svn diff]')
        call append(7, '" u : 更新所有文件[svn update]***')
        call append(8, '" a : 其他')
        call append(9, '" s : 将待提交列表中的文件提交到svn[svn commit]')
        call append(10, '" <F1> : 隐藏帮助信息')
    endif
endfunction

function! s:Window_Update_Line_Offsets(start_idx, increment, offset)
    let i = a:start_idx

    while i < s:file_count
        if s:tlist_{i}_visible
            " Update the start/end line number only if the file is visible
            if a:increment
                let s:tlist_{i}_start = s:tlist_{i}_start + a:offset
                let s:tlist_{i}_end = s:tlist_{i}_end + a:offset
            else
                let s:tlist_{i}_start = s:tlist_{i}_start - a:offset
                let s:tlist_{i}_end = s:tlist_{i}_end - a:offset
            endif
        endif
        let i = i + 1
    endwhile
endfunction

" 高亮或取消高亮文件行
function! Q_SvnMatchFile(...)
    let match_list = getmatches()
    let check = 0
    for item in match_list
        if has_key(item,'pos1') && item['pos1']== [a:1]
            let check = 1
            call matchdelete(item['id'])
        endif
    endfor
    if check == 0
        call matchaddpos('DiffChange', [a:1])
    endif
endfunction

" 清空所有高亮
function! Q_SvnClearMatchFile(...)
    let match_list = getmatches()
    for item in match_list
        call matchdelete(item['id'])
    endfor
endfunction

" 显示svn st列表
function! Q_SvnStatus(...)
    if buffer_name('%') != ''
        tabnew
    endif

    setlocal modifiable
    let win_id = win_getid()
    call setqflist([])
    call clearmatches()
    copen
    echo 'svn status ...'
    let cmd = 'svn st'
    let cmd = cmd.' | egrep -v "'.join(g:svn_ignore, "|").'"'

    call win_gotoid(win_id)
    execute '1,'.line('$').' delete'

    call s:Window_Display_Help()
    execute 'read !'.cmd
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal nomodifiable
    setlocal cursorline
    let file_num = line('$') - 3
    setlocal statusline=\ [{file_num}]\ Files
    " 定义快捷键
    nnoremap <buffer> <silent> <F1> :call <SID>Window_Toggle_Help_Text()<CR>
    " 加入提交列表
    map <silent><buffer> <CR> :call Q_SvnSet(line('.'), getline('.'))<CR>
    map <silent><buffer> o :call Q_SvnSet(line('.'), getline('.'))<CR>
    " 删除提交列表
    map <silent><buffer> d :call Q_SvnUnset(line('.'), getline('.'))<CR>
    map <silent><buffer> x :call Q_SvnUnset(line('.'), getline('.'))<CR>
    map <silent><buffer> t :call Q_SvnOpen(getline('.'))<CR>
    map <silent><buffer> r :call Q_SvnRervert(getline('.'))<CR>
    map <silent><buffer> d :call Q_SvnDiff(getline('.'))<CR>
    map <silent><buffer> u :call Q_SvnUpdate()<CR>
    " 提交到svn
    map <silent><buffer> s :call Q_SvnCommit()<CR>
    echohl None
endfunction

function! Q_SvnUpdate(...)
    let msg = input('确定要更新当前项目吗？ Y/n：')
    if msg == 'Y'
        call Q_SvnExecute("svn update ", 1)
        call Q_SvnStatus()
    endif
endfunction


function! Q_SvnRervert(...)
    let msg = input('确定要回滚文件吗？ Y/n：')
    if msg == 'Y'
        let var_item = split(a:1, " ")
        let item_type = var_item[0]
        let item_file = var_item[-1]

        call Q_SvnExecute("svn revert ".item_file)
        call Q_SvnStatus()
    endif
endfunction

function! Q_SvnDiff(...)
    let var_item = split(a:1, " ")
    let item_type = var_item[0]
    if item_type == 'M'
    let item_file = var_item[-1]
        call Q_SvnExecute("svn diff ".item_file, 1)
    else
        echohl WarningMsg | echo '文件不在版本库里' | echohl None
    endif
endfunction

function! Q_SvnOpen(...)
    let var_item = split(a:1, " ")
    let item_type = var_item[0]
    let item_file = var_item[-1]
    execute "tabnew ".item_file
endfunction

" 添加文件到待提交列表
function! Q_SvnSet(...)
    if a:2 != ''
        let var_list = getqflist()
        let var_item = split(a:2, " ")
        let item_type = var_item[0]
        let item_file = var_item[-1]
        if(item_type == '"')
            return
        endif
        " 添加高亮
        call matchaddpos('DiffChange', [a:1])

        " 加入quickfix
        let check = 0
        if !empty(var_list)
            for item in var_list
                if item['pattern'] == item_file
                    let check = 1
                endif
            endfor
        endif
        if check == 0
            call add(var_list, {'pattern' : item_file, 'text' : item_type})
        endif
        call setqflist(var_list)
    endif
endfunction

" 删除待提交文件
function! Q_SvnUnset(...)
    if a:2 != ''
        let var_list = getqflist()
        let var_item = split(a:2, " ")
        let item_type = var_item[0]
        let item_file = var_item[-1]
        " 删除高亮
        call matchaddpos('DiffChange', [a:1])
        let match_list = getmatches()
        for item in match_list
            if has_key(item,'pos1') && item['pos1']== [a:1]
                call matchdelete(item['id'])
            endif
        endfor

        " 重新生成quickfix
        let ret_list = []
        if !empty(var_list)
            for item in var_list
                if item['pattern'] != item_file
                    call add(ret_list, {'pattern' : item['pattern'], 'text' : item['text']})
                endif
            endfor
        endif
        call setqflist(ret_list)
    endif
endfunction

" 将待提交文件上传到svn
function! Q_SvnCommit()
    let qlist = getqflist()
    if empty(qlist)
        echohl WarningMsg | echo '没有选择文件' | echohl None
        return
    endif
    let add_list = []
    let update_list = []
    for item in qlist
        call add(update_list, item['pattern'])
        if item['text'] == '?'
            call add(add_list, item['pattern'])
        endif
    endfor
    " 拼装需要新增的文件列表
    let svn_cmd_add = "svn add "
    if !empty(add_list)
        for item in add_list
            let svn_cmd_add = svn_cmd_add.' '.item
        endfor
        echohl WarningMsg | echo svn_cmd_add | echohl None
    else
        let svn_cmd_add = ""
    endif
    " 拼装需要提交的文件列表
    let svn_cmd_commit = "svn commit -m 'MESSAGE' "
    if !empty(update_list)
        for item in update_list
            let svn_cmd_commit = svn_cmd_commit.' '.item
        endfor
        echohl WarningMsg | echo svn_cmd_commit | echohl None
    else
        echohl ErrorMsg | echo '提交失败：提交列表为空' | echohl None
        return
    endif
    " 输入注释
    let msg = input('请输入注释信息 MESSAGE :')
    echo "\n"
    if msg  == ""
        echohl ErrorMsg | echo '提交失败：注释不能为空' | echohl None
        return
    else
        let svn_cmd_commit = substitute(svn_cmd_commit, "MESSAGE", msg, "")
        if svn_cmd_add != ""
            call Q_SvnExecute(svn_cmd_add, 2)
        endif
        call Q_SvnExecute(svn_cmd_commit, 1)
         call Q_SvnStatus()
        " echohl SpellLocal | echo '操作完成' | echohl None
    endif
endfunction

function! Q_SvnExecute(...)
    if a:0 >1 && a:2 == 1
        execute "!".a:1
        return 1
    elseif a:0 >1 && a:2 == 2
        let cmd = a:1
        echo cmd
        :silent let str=system(cmd)
    else
        if g:svn_async == 1
            let cmd = shellescape(a:1)
            execute "AsyncRun ".cmd
        else
            " execute "!".a:1
            let cmd = a:1
            :silent let str=system(cmd)
            echo str
        endif
    endif
endfunction

