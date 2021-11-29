commands$="run upload dir help list reset "
line$=""
prgline$=""
param$=""
XON$=chr$(17)
XOFF$=chr$(19)

print bas.ver$ ; "  REPL"
print "Ram Available "; ramfree
onserial on_serial

print ">";

wait

on_serial:
c$=serial.chr$
if c$=chr$(127) then
  line$=left$(line$, len(line$)-1)
  print c$;
  return
endif
if c$=chr$(13) then
  if left$(line$,1) = "?" then
    line$="print" + mid$(line$, 2)
  endif
  print
  if word.find(commands$, word$(line$, 1)) <> 0 then
    cmd$=word$(line$, 1)
'    print "Command found :", "_";cmd$;"_"
    param$=word.delete$(line$, 1)
'    print "  params: ", "_";param$;"_"
    line$=""
    gosub cmd$
    print "OK"
    print ">";
  else
    onerror skip 1
    command line$
    line$=""
    if bas.errnum=0 then
      print "OK"
    else
      print "Error:"; bas.errnum; "  (" ; bas.errmsg$; ")"
    endif
    print ">";
  endif
else
  print c$;
  line$=left$(line$+c$, 200)
endif
return

sub mkfn(p$)
  if left$(p$, 1) <> "/" then
    p$="/"+p$
  endif
  if instr(p$, ".") = 0 then
    p$=p$+".bas"
  endif
end sub

run:
  mkfn param$
  x=bas.load param$
  print param$; " file not found."
  print ">";
return

upload:
  mkfn param$
  filename$=param$
  file.save "/filename.txt", filename$
  x=bas.load "/repl/uploader.bas"
return

dir:
d$ = FILE.DIR$("/")
While D$ <> ""
  Print d$
  d$ = FILE.DIR$
Wend
return


help:
  print "run filename"
  print "dir"
  print "list filename"
  print "upload filename [paste file contents into the terminal. The EOF sign is '§']"
  print "reset"
  print "help"
return


list:
  mkfn param$
  if file.exists(param$) = 0 then 
    print param$; " file not found."
  else
    i=1
    l$=file.read$(param$)
    lc=word.count(l$, chr$(13))
    for i=1 to lc
      print word$(l$, i, chr$(13))
    next
  endif
return

reset:
  option.wdt 1
return
