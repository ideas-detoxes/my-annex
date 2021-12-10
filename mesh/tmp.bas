myself$=right$(mac$, 5)
dly=val("&H"+right$(mac$, 2))
pktcnt=1
startttl=2
ttl=0
cache$="xXx"
msgid=millis mod 1000
count=32
mask=count-1
dim msg$(count)
rptr=0
wptr=0
lastmessage$=""
menu$="@"+"s|Send|send"
menu$="s|Send|send"
'menu$=menu$+"@"+"p|PING|sendping"

onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu

espnow.begin
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"


main:
  gosub printmenu
do while 1
  if rptr<>wptr then
    html "<table border=1>"
    msg$=msg$(rptr)
    rptr=(rptr+1) and 31
    printpacket "Received", msg$
    if instr(cache$, left$(msg$, 22)) then 
      html "<tr><td>cachecheck<td colspan=4>exist in cache<td></tr>"
    else  
      cache$=left$(cache$+left$(msg$, 22), 3000)
      forward msg$
    end if  
    html "</table>"
  endif  
loop
p$=""



sub splitpacket(pkt$, from$, msgid$, ttl$, payload$)
  from$   ="--:--:--:--:--:--"
  payload$="-----------------"
  if word.count(pkt$, "|") = 3 then
    from$   ="--:--:--:--:--:--"
    msgid$  =word$(pkt$, 1, "|")
    ttl$    =word$(pkt$, 2, "|")
    payload$=word$(pkt$, 3, "|")
  end if
  if word.count(pkt$, "|") = 4 then
    from$   =word$(pkt$, 1, "|")
    msgid$  =word$(pkt$, 2, "|")
    ttl$    =word$(pkt$, 3, "|")
    payload$=word$(pkt$, 4, "|")
  end if
end sub


sub joinpacket(pkt$, msgid, ttl, payload$)
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  end if
  pkt$=str$(msgid, "%04.0f")+"|"+str$(ttl)+"|"+payload$
end sub

sub printpacket(pre$, pkt$)
local from$, msgid$, ttl$, payload$
  splitpacket pkt$, from$, msgid$, ttl$, payload$
  h$="<tr><td>"+pre$+"<td>"+from$+"<td>"+msgid$+"<td>"+ttl$+"<td>"+payload$+"</tr>"
  html h$
'  wlog h$
  pktcnt=pktcnt+1
  if pktcnt > 25 then
    pktcnt=0
    gosub printmenu
  end if
end sub

processmenu:
  c$=left$(HtmlEventButton$,1)
  itemcnt=word.count(menu$)
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    if c$<>"" and instr(word$(item$, 1, "|"), c$) then
      g$=word$(item$, 3, "|")
      gosub g$
      c$=""
    end if
  next i
return

printmenu:
  menukey$=""
  cls
  h$="<h1>"+myself$+"</h1><br><hr><br>"
  h$=h$+"<br>"+textarea$(lastmessage$)+"<br>"  
  itemcnt=word.count(menu$, "@")
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    h$=h$+ "<br>"
    h$=h$+ button$(word$(item$, 1, "|") + "---" + word$(item$,2,"|"), processmenu)
    menukey$=menukey$+word$(item$, 1, "|")
  next i
  html h$
return
  
sub sendpacket(payload$)
'sub joinpacket(pkt$, msgid, ttl, payload$)
local pkt$
  joinpacket pkt$, msgid, 2, payload$
    html "<table border=1>"
    printpacket "sendpacket", pkt$
    html "</table>"

  espnow.add_peer("ff:ff:ff:ff:ff:ff")
  espnow.write(pkt$)
  espnow.del_peer("ff:ff:ff:ff:ff:ff")
  cache$=left$(cache$+left$(mac$+"|"+pkt$, 22), 3000)
end sub
 
 
sub forward(pkt$)
local i, tmp$, msgid$, msgid
    tmp$=mid$(pkt$, 19)
    ttl=val(word$(tmp$, 2, "|"))-1
    if ttl <= 0 then
      printpacket "dont forward, expired", pkt$
    else
    wlog tmp$
      tmp$=word$(tmp$,1,"|")+"|"+str$(ttl)+"|"+word$(tmp$,3,"|")
    wlog tmp$
      for i=1 to dly
      next i
      html "<table border=1>"
      printpacket "forward", tmp$
      html "</table>"
      espnow.add_peer("ff:ff:ff:ff:ff:ff")
      espnow.write(tmp$)
      espnow.del_peer("ff:ff:ff:ff:ff:ff")
    endif
end sub  


send:
  p$="Hello from "+myself$+" "+str$(msgid)
  sendpacket p$

  return  
  
message:
  msg$(wptr) = ucase$(espnow.remote$)+"|"+espnow.read$
  wptr=(wptr+1) and 31
  return
  
  
status:
  printlog "TX error on "+ espnow.error$  ' print the error
  print "TX error on "+ espnow.error$  ' print the error
  return

