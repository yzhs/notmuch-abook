" Address book management


if exists("g:notmuch_addressbook")
    finish
else
    let g:notmuch_addressbook = 1
endif

if !has('python') && !has('python3')
    echoerr "Error: Notmuch Addressbook plugin requires Vim to be compiled with +python"
    finish
endif

" Init link to Addressbook database
fun! InitAddressBook()
    if has('python')
        py import vim
        py import notmuch_abook
        py cfg = notmuch_abook.NotMuchConfig(None)
        py db = notmuch_abook.SQLiteStorage(cfg) if cfg.get("addressbook", "backend") == "sqlite3" else None
    else
        py3 import vim
        py3 import notmuch_abook
        py3 cfg = notmuch_abook.NotMuchConfig(None)
        py3 db = notmuch_abook.SQLiteStorage(cfg) if cfg.get("addressbook", "backend") == "sqlite3" else None
    endif
endfun

" Addressbook completion
fun! CompleteAddressBook(findstart, base)
    let curline = getline('.')
    if curline =~ '^From: ' || curline =~ '^To: ' || curline =~ 'Cc: ' || curline =~ 'Bcc: '
        if a:findstart
        " locate the start of the word
            let start = col('.') - 1
            while start > 0 && curline[start - 2] != ":" && curline[start - 2] != ","
                let start -= 1
            endwhile
            return start
        else
            if has('python')
python << EOP
encoding = vim.eval("&encoding")
if db:
    for addr in db.lookup(vim.eval('a:base')):
        if addr[0] == "":
            addr = addr[1]
        else:
            addr = addr[0]+" <"+addr[1]+">"
        vim.command('call complete_check()')
        vim.command(('call complete_add("{}")'.format(addr.replace('"', ""))).encode( encoding ))
else:
    vim.command('echoerr "No backend found."')
EOP
            else
python3 << EOP
encoding = vim.eval("&encoding")
if db:
    for addr in db.lookup(vim.eval('a:base')):
        if addr[0] == "":
            addr = addr[1]
        else:
            addr = addr[0]+" <"+addr[1]+">"
        vim.command('call complete_check()')
        vim.command(('call complete_add("{}")'.format(addr.replace('"', ""))).encode( encoding ))
else:
    vim.command('echoerr "No backend found."')
EOP
            endif
            return []
        endif
    endif
endfun

augroup notmuchabook
    au!
    au FileType mail,notmuch-compose call InitAddressBook()
    au FileType mail,notmuch-compose setlocal completefunc=CompleteAddressBook
augroup END

