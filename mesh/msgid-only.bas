myself$=right$(mac$, 5)
mynum=val("&H"+right$(mac$, 2))
pktcnt=1
startttl=3
cache$="xXx"
msgid=1
count=32
mask=count-1
dim msg$(count)
rptr=0
wptr=0
lastmessage$=""
menu$="@"+"s|Send|send"
menu$="s|Send|send"
'menu$=menu$+"@"+"p|PING|sendping"
counter=1

onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu
espnow.begin
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

nextsend=millis+111+rnd(1000)
main:
  gosub printmenu
do while 1
  if rptr<>wptr then
    gosub processq
  endif  
  if millis > nextsend then
    nextsend=millis+333+rnd(1000)
    gosub send
  end if
loop


processq:
  if rptr<>wptr then
    html "<table border=1>"
    msg$=msg$(rptr)
    rptr=(rptr+1) and 31
    advance_msgid msg$
    if instr(cache$, word$(msg$, 1, "|"))>0 then 
'      html "<tr><td>cachecheck<td colspan=4>exist in cache<td></tr>"
    else  
      printpacket "Received", msg$
      cache$=left$(cache$+ " "+word$(msg$, 1, "|") , 1000)
      forward msg$
    end if  
    html "</table>"
  endif  
return


sub advance_msgid(pkt$)
local tmp, i
  tmp=val(word$(pkt$, 1, "|"))
  if tmp > msgid then
    msgid=tmp
    for i=1 to mynum
      msgid=msgid+1
    next
    if msgid > 9999 then
      msgid=1
    end if    
  end if
end sub

sub splitpacket(pkt$, msgid$, ttl$, payload$)
  payload$="-----------------"
  if word.count(pkt$, "|") = 3 then
    msgid$  =word$(pkt$, 1, "|")
    ttl$    =word$(pkt$, 2, "|")
    payload$=word$(pkt$, 3, "|")
  end if
end sub


sub joinpacket(pkt$, msgid, ttl, payload$)
  msgid=msgid+1
  if msgid > 9999 then
    msgid=1
  end if
  pkt$=str$(msgid, "%04.0f")+"|"+str$(ttl)+"|"+payload$
end sub

sub printpacket(pre$, pkt$)
local msgid$, ttl$, payload$
  splitpacket pkt$, msgid$, ttl$, payload$
  h$="<tr><td>"+str$(ramfree)+"<td>"+str$(millis)+"<td>"+pre$+"<td>"+msgid$+"<td>"+ttl$+"<td>"+payload$+"</tr>"
  html h$
'  wlog h$
  pktcnt=pktcnt+1
  if pktcnt > 25 then
    pktcnt=0
    cls
'    gosub printmenu
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
  h$="<h3>"+myself$+"</h3>"
  itemcnt=word.count(menu$, "@")
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    h$=h$+ button$(word$(item$, 1, "|") + "---" + word$(item$,2,"|"), processmenu)
    h$=h$+ "<br>"
    menukey$=menukey$+word$(item$, 1, "|")
  next i
  html h$
return
  
sub sendpacket(payload$)
local pkt$
  joinpacket pkt$, msgid, startttl, payload$
    html "<table border=1>"
    printpacket "sendpacket", pkt$
    html "</table>"

  espnow.add_peer("ff:ff:ff:ff:ff:ff")
  espnow.write(pkt$)
  espnow.del_peer("ff:ff:ff:ff:ff:ff")
  cache$=left$(cache$+ " "+word$(pkt$, 1, "|") , 1000)
end sub
 
 
sub forward(pkt$)
local i, tmp$, msgid$, msgid
  tmp$=pkt$
    ttl=val(word$(tmp$, 2, "|"))-1
    if ttl <= 0 then
'      printpacket "dont forward, expired", pkt$
    else
      tmp$=word$(tmp$,1,"|")+"|"+str$(ttl)+"|"+word$(tmp$,3,"|")
      html "<table border=1>"
'      printpacket "forward", tmp$
      html "</table>"
      espnow.add_peer("ff:ff:ff:ff:ff:ff")
      espnow.write(tmp$)
      espnow.del_peer("ff:ff:ff:ff:ff:ff")
    endif
end sub  


send:
  p$="Hello from "+myself$+" "+str$(msgid) + " " + str$(counter)
  counter=counter+1
  sendpacket p$
return  
  
message:
  msg$(wptr) = espnow.read$+" ("+ESPNOW.REMOTE$+")"
  print millis, msg$(wptr)
  wptr=(wptr+1) and 31
  return
  
  
status:
  printlog "TX error on "+ espnow.error$  ' print the error
  print "TX error on "+ espnow.error$  ' print the error
  return

