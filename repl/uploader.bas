commands$="run upload "
mode$=""
line$=""
prgline$=""
param$=""

print "Uploader"
print "Ram Available "; ramfree

filename$=file.read$("/filename.txt")
if filename$="" then
  print "Filename is missing."
  print bas.load "/r.bas"
endif
if left$(filename$, 1) <> "/" then
  filename$="/"+filename$
endif
print "FileName: ";filename$

while 1
    s$=serial.input$
    do while s$=""
      s$=serial.input$
    loop
    t$=t$+s$
    if instr(s$, "§") <> 0 then
      tt$=replace$(t$, chr$(13), "")
      print "saving to: ";filename$
      x=file.delete(filename$)
      file.save filename$, t$
      print bas.load "/repl/repl.bas"
    endif
wend
