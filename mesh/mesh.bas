msg$ = ""
from$ = ""
nodes$=""
msgid=millis mod 1000
cachemax=3000
cache$=""
iam$="node_"+word$(WORD$(IP$,1),4,".")
groups$="any group1"
menukey$=""
menu$=""
menu$=menu$+""+"?|Help|help" ' keycode(s)|menutext|label
menu$=menu$+"@"+"1|Send to node 1|sendtonodex"
menu$=menu$+"@"+"2|Send to node 2|sendtonodex"
menu$=menu$+"@"+"3|Send to node 3|sendtonodex"
menu$=menu$+"@"+"4|Send to node 4|sendtonodex"
menu$=menu$+"@"+"5|Send to node 5|sendtonodex"
menu$=menu$+"@"+"6|Send to node 6|sendtonodex"
menu$=menu$+"@"+"a|Send to group Any|sendtogroupany"
menu$=menu$+"@"+"n|Print peer nodes|printnodes"
'menu$=menu$+"@"+"p|Print peer MACs|printpeers"
'menu$=menu$+"@"+"s|Scanning|doscan"
'menu$=menu$+"@"+"b|Send broadcast|sendbroadcast"
menu$=menu$+"@"+"q|Quit|quit"


'onError goto lblerror
onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu

espnow.begin
espnow.add_peer("ff:ff:ff:ff:ff:ff")
WIFI.APMODE "ESP="+iam$, "abrakadabra"


gosub printmenu 
print menukey$

do while 1
  if msg$ <> "" then
    print "packet received: ";msg$;" from: ";from$
    html "<br>packet received: "+msg$+" from: "+from$
    processpacket msg$, from$
    msg$= ""
    from$=""
  endif
  c$=serial.chr$
  if c$<>"" then
    if c$=" " then
      gosub printmenu 
    endif
    if instr(menukey$, c$) <> 0 then
      gosub processmenu 
    endif
  endif
loop

end

processmenu:
  if c$="" then
   c$=left$(HtmlEventButton$,1)
  endif
  itemcnt=word.count(menu$)
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    if c$<>"" and instr(word$(item$, 1, "|"), c$) then
      g$=word$(item$, 3, "|")
      gosub g$
      c$=""
    endif
  next
return

printmenu:
  menukey$=""
  cls
  h$="<h1>"+iam$+"</h1><br><hr><br>"
  itemcnt=word.count(menu$, "@")
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    print word$(item$, 1, "|")," - ";word$(item$,2,"|")
    h$=h$+ "<br>"
    h$=h$+ button$(word$(item$, 1, "|") + "---" + word$(item$,2,"|"), processmenu)
    menukey$=menukey$+word$(item$, 1, "|")
  next
  html h$
return

help:
  return

sendtonodex:
'  print "Send to peer X"
  html "<br>send to peer:" + c$
  peer=asc(c$) - asc("0")
  p$="Hello from "+iam$
  makepacket p$, word$(nodes$, peer)
  print "Sending packet: ";p$
  html "<br>Sending packet: " + p$
  espnow.write(p$)
  uniq$=word$(p$, 1, "|")+word$(p$, 2, "|")
  cache$=left$(uniq$+cache$, cachemax)
  return
sendtogroupany:
  html "<br>send to all peers"
  p$="Hello from "+iam$
  makepacket p$, "any"
  print "Sending packet: ";p$
  html "<br>Sending packet: " + p$
  espnow.write(p$)
  uniq$=word$(p$, 1, "|")+word$(p$, 2, "|")
  cache$=left$(uniq$+cache$, cachemax)
  return
printpeers:
  print "Current MACs of peers:"
  html "<br>Current MACs of peers:<br>"
  for i=1 to word.count(peers$)
    print i, word$(peers$, i)
    html str$(i) + "   " +  word$(peers$, i) + "<br>"
  next i
  return
printnodes:
  print "Current peer nodes:"
  html "<br>Current peer nodes:<br>"
  for i=1 to word.count(nodes$)
    print i, word$(nodes$, i)
    html str$(i) + "   " +  word$(nodes$, i) + "<br>"
  next i
  return
doscan:
  print "Scan start ...  ";
  html "<br>Scan start ...  ";
  msg$ = ""
  from$ = ""
  peers$ = ""
  doScan
  print "Scan done."
  html "Scan done.<br>"
  return
quit:
  print "Quit"
  print bas.load "/repl/repl.bas"
  return



sub processpacket(p$, from$)
  if from$="" then
    trace "from$=''"
    exit sub
  endif
  uniq$=word$(p$, 1, "|")+word$(p$, 2, "|")
  if uniq$="" then
    trace "uniq=''"
    exit sub
  endif
  src$=word$(p$, 2, "|")
  dst$=word$(p$, 3, "|")
  print "src: " + src$
  html "<br>src: " + src$
  print "dst: " + dst$
  html "<br>dst: " + dst$
  ' add src to knonw nodes
  wlog "_"+nodes$+"_", "-"+src$+"-"
  if instr(nodes$, src$) = 0 and src$ <> iam$ then
    if nodes$="" then
      nodes$=src$
    else
      nodes$=nodes$+" "+src$
    endif
  endif
  if instr(cache$, uniq$) then
    print "exist in cache"
    html "<br>exist in cache"
    exit sub
  endif
  cache$=left$(uniq$+cache$, cachemax)
  forme=0
  ' en vagyok a cimzett
  if dst$ = iam$ then
    forme=1
  endif
  ' olyan csoportnak cimeztek-e, aminek tagja vgyok ?
  grouptarget=0
  x=word.count(groups$)
  for i=1 to x
    if word$(groups$, i) = dst$ then
      grouptarget=grouptarget+1
      forme=forme+1
    endif
  next
  ' nem en vagy nem csak en vagyok a cimzett, tovabbitani kell a csomagot
  if (forme=0) or (grouptarget>0) then
    espnow.write(p$)
  endif
  ' kozvetlenul vagy csoporttagsagon keresztul en vagyok a cimzett
  if forme > 0 then
        userprocess p$, from$
  endif
end sub


sub makepacket(payload$, dst$)
  payload$=str$(msgid, "%04.0f")+"|"+iam$+"|"+dst$+"|"+payload$
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  endif
end sub

sub userprocess(p$, from$)
    html "<br>Valid packet received:  " + p$  
end sub
 


message:
  msg$  = espnow.read$
  from$ = ucase$(espnow.remote$)
  return

status:
  wlog "TX error on "; espnow.error$  ' print the error
  print "TX error on "; espnow.error$  ' print the error
  return

lblerror:
  wlog bas.errmsg$+" in line "+str$(bas.errline)+" ("+str$(bas.errnum)+")"
  print bas.errmsg$+" in line "+str$(bas.errline)+" ("+str$(bas.errnum)+")"
  trace bas.errmsg$+" in line "+str$(bas.errline)+" ("+str$(bas.errnum)+")"
  return
  
'§§
