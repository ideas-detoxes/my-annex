msg$ = ""
from$ = ""
peers$ = ""
msgid=millis mod 1000
shortmac$=replace$(mac$, ":", "")
cachemax=100*16  ' header len=16, max entry count=100
cache$=""
iam$=word$(WORD$(IP$,1),4,".")
iam$="B6E62D13F307"
groups$="any group1"
menukey$=""
menu$=""
menu$=menu$+""+"?|Help|help" ' keycode(s)|menutext|label
menu$=menu$+"@"+"1-9|Send to peer [1-9]|sendtopeerx"
menu$=menu$+"@"+"p|Print peers|printpeers"
menu$=menu$+"@"+"s|Scanning|doscan"
menu$=menu$+"@"+"b|Send broadcast|sendbroadcast"
menu$=menu$+"@"+"q|Quit|quit"
'menu$=menu$+"@"
help:

onEspNowError status
onEspNowMsg message 

espnow.begin
WIFI.APMODE "ESP=", "abrakadabra"


doScan
printmenu menu$, menukey$
print menukey$

do while 1
  if msg$ <> "" then
    print "packet reveived: ";msg$;" from: ";from$
    processpacket msg$, from$
    msg$= ""
    from$=""
  endif
  c$=serial.chr$
  if c$<>"" then
    if c$=" " then
      printmenu menu$, menukey$
    endif
    if instr(menukey$, c$) <> 0 then
      processmenu c$
    endif
  endif
loop

end

sub processmenu(c$)
  itemcnt=word.count(menu$)
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    if c$<>"" and instr(word$(item$, 1, "|"), c$) then
      g$=word$(item$, 3, "|")
      gosub g$
      c$=""
    endif
  next
end sub

sub printmenu(menu$, menukey$)
  menukey$=""
  itemcnt=word.count(menu$)
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    print word$(item$, 1, "|")," - ";word$(item$,2,"|")
    menukey$=menukey$+word$(item$, 1, "|")
  next
end sub

sendtopeerx:
'  print "Send to peer X"
  peer=asc(c$) - asc("0")
  p$="Hello from "+iam$
  makepacket p$, word$(peers$, peer)
  print "Sending packet: ";p$
  espnow.write(p$)
  return
printpeers:
  print "Current peers:"
  for i=1 to word.count(peers$)
    print i, word$(peers$, i)
  next i
  return
doscan:
  print "Scan start ...  ";
  msg$ = ""
  from$ = ""
  peers$ = ""
  doScan
  print "Scan done."
  return
sendbroadcast:
  print "Send BroadCast"
  return
quit:
  print "Quit"
  return



sub processpacket(p$, from$)
wlog "pp:", p$
wlog "pp: ", from$
  shortfrom$=ucase$(replace$(from$, ":", ""))
  uniq$=left$(p$, 16)
  if instr(cache$, uniq$) then
    print "exist in cache"
    exit sub
  endif
  if instr(peers$, shortfrom$) = 0 then
    if peers$="" then
      peers$ = shortfrom$
    else
      peers$=peers$+" "+shortfrom$
    endif
    espnow.add_peer(from$)
  endif
  cache$=left$(uniq$+cache$, cachemax)
  dst$=word$(p$, 2, "|")
  print "cimzett: " + dst$
  x=word.count(groups$)
  groupmatch=0
  forme=0
  if dst$ = iam$ then
    forme=1
  endif
  for i=1 to x
    if word$(groups$, i) = dst$ then
      groupmatch=groupmatch+1
      forme=forme+1
    endif
  next
  if (groupmatch > 0) or (forme=0) then
    forwardpacket p$, shortfrom$
  endif
  if forme > 0 then
        userprocess p$
  endif
end sub

sub forwardpacket p$, f$
  cnt=word.count(peers$)
  for i=1 to cnt
    n$=word$(peers$, i)
    if n$ <> f$
      html "<br>    forwarding to: " + n$
    endif
  next
end sub

sub makepacket(payload$, dst$)
  payload$=str$(msgid, "%04.0f")+shortmac$+"|"+dst$+"|"+payload$
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  endif
end sub

sub doScan
  WIFI.SCAN
  While WIFI.NETWORKS(A$) = -1
  Wend
  lc = word.count(a$, chr$(10))
  for i = 1 to lc
    line$ = word$(a$, i, chr$(10))
    if word$(line$, 1, ",") = "ESP=" then
      peers$ = peers$ + replace$(word$(line$, 2, ","), ":", "") + " "
      espnow.add_peer(word$(line$, 2, ","))
    endif
  next i
  if peers$ <> "" then
    peers$=left$(peers$, len(peers$)-1)
  endif
end sub

sub userprocess(p$)
    print "Valid packet received:  " + p$  
end sub
 


message:
  msg$  = espnow.read$
  from$ = espnow.remote$ 
  return

status:
  wlog "TX error on "; espnow.error$  ' print the error
  print "TX error on "; espnow.error$  ' print the error
  return


