test=1
myself$=ucase$("node-"+word$(WORD$(IP$,1),4,"."))
startttl=2
dim cn$(4) = "NODE-140","NODE-190","NODE-200","NODE-251"
dim cp$(4) = "82:7D:3A:47:62:20","B6:E6:2D:13:F3:07","5E:CF:7F:1A:FD:24","B6:E6:2D:13:F3:44"

allowedpeers$=""
allowednodes$=""
for i=0 to 4
  if cn$(i)=myself$ then 
    my=i
  else
    allowednodes$=allowednodes$+" "+cn$(i)
  end if
next
if (my-1) >= 0 then
  allowedpeers$=allowedpeers$+" "+cp$(my-1)
end if
if (my+1) < 4 then
  allowedpeers$=allowedpeers$+" "+cp$(my+1)
end if
if (my+2) < 4 then
  allowedpeers$=allowedpeers$+" "+cp$(my+2)
end if

allowednodes$=trim$(allowednodes$)
allowedpeers$=trim$(allowedpeers$)
 
' msgid|src     |dst|payload
'  0509|node_200|any|Hello from node_200
msg$=""
from$=""
cache$="xXx"
nodes$=""
peers$=""
groups$=ucase$("any group1 group2")
msgid=millis mod 1000

count=32
mask=count-1
dim msg$(count)
dim from$(count)
rptr=0
wptr=0


menukey$=""
menu$=""
nodecnt=word.count(allowednodes$)
for i=1 to nodecnt
  if menu$="" then
    menu$=""+str$(i)+"|Send to:"+word$(allowednodes$, i)+"|sendtonodex"
  else
    menu$=menu$+"@"+str$(i)+"|Send to:"+word$(allowednodes$, i)+"|sendtonodex"
  end if
next

menu$=menu$+"@"+"a|Send to group Any|sendtogroupany"
menu$=menu$+"@"+"p|PING|sendping"

hbinterval = 10000 ' ms
nexthb = millis + hbinterval
lastmessage$=""

onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu

espnow.begin
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"


gosub printmenu 
refresh

pktcnt=0
do while 1
  if test=1 then
    peers$=allowedpeers$
    nodes$=allowednodes$
  end if
  if rptr<>wptr then
    msg$=msg$(rptr)
    from$=ucase$(from$(rptr))
    rptr=(rptr+1) and 31

    flag=0
    if test=0 then flag=flag+1
    if test=1 and instr(allowedpeers$, from$)>0 then flag=flag+1
    if flag > 0 then
      if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
        html "<table border=1>"
        html "<tr><td>stage<td>msgid<td>from<td>to<td>payload<td>src/dst</tr>"
        printpacket "received", msg$, from$
      end if
      processpacket msg$, from$
      if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
        html "</table>"
      end if
      msg$=""
      from$=""
    end if 
    refresh
  else
    if pktcnt > 20 then
      pktcnt=0
      gosub printmenu
    end if
    if millis > nexthb then
      nexthb = millis + hbinterval
      p$="PING from "+myself$
      sendpacket p$, "broadcast"
    end if
  end if
loop

end

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
  h$="<h1>"+myself$+" ("+mac$+")</h1><br><hr><br>"
  h$=h$+"<table><tr><td>"+textarea$(peers$)+"<td>"+textarea$(nodes$)+"</table>"
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

help:
  return

sendtonodex:
  html "<br>send to peer:" + c$
  for ii=1 to 1
  p$="Hello from "+myself$
    node=asc(c$) - asc("0")
    sendpacket p$, word$(allowednodes$, node)
  next
  return
sendtogroupany:
  for ii=1 to 1
    p$="Hello from "+myself$
    sendpacket p$, "ANY"
  next
  return
sendping:
'  html "<br>send broadcast PING"
  for ii=1 to 1
    p$="PING from "+myself$
    sendpacket p$, "broadcast"
  next
  return


sub printpacket(pre$, pkt$, frm$)
  local msgid$, src$, dst$, ttl$, payload$, h$
  msgid$  =word$(pkt$, 1, "|")
  src$    =word$(pkt$, 2, "|")
  ttl$    =word$(pkt$, 4, "|")
  payload$=word$(pkt$, 5, "|")
  h$="<tr><td>"+pre$+"<td>"+msgid$+"<td>"+src$+"<td>"+ttl$+"<td>"+payload$+"<td>"+frm$+"</tr>"
  html h$
  pktcnt=pktcnt+1
  if pktcnt > 25 then
    pktcnt=0
    gosub printmenu
  end if
end sub
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''



sub addtocache(msg$)
  local msgid$, src$, dst$, payload$, ttl$, uniq$
  msgid$  =word$(msg$, 1, "|")
  src$    =word$(msg$, 2, "|")
  dst$    =word$(msg$, 3, "|")
  ttl$    =word$(msg$, 4, "|")
  payload$=word$(msg$, 5, "|")
  uniq$   =msgid$+src$
  addtostr uniq$, cache$, 3000, ""
end sub 

sub makepacket(payload$)
  payload$=str$(msgid, "%04.0f")+"|"+str$(startttl)+"|"+payload$
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  end if
end sub

sub processpacket(msg$, from$)
  local msgid$, src$, dst$, ttl$, payload$, uniq$, token$, i, tmp
  if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
    printpacket "processpacket", msg$, from$
  end if
  if word.count(msg$, "|") <> 5 then 
    exit sub 
  end if
  msgid$  =word$(msg$, 1, "|")
  src$    =ucase$(word$(msg$, 2, "|"))
  dst$    =ucase$(word$(msg$, 3, "|"))
  ttl$    =ucase$(word$(msg$, 4, "|"))
  payload$=ucase$(word$(msg$, 5, "|"))
  uniq$   =ucase$(msgid$+src$)
  token$  =word$(payload$,1)
  if instr(cache$, uniq$) then 
    if instr(payload$, "PINGG")=0 and instr(payload$, "PONG")=0 then
      html "<tr><td>processpacket<td colspan=4>exist in cache<td></tr>"
    end if
    exit sub 
  end if
  addtocache msg$
  addtostr ucase$(from$), peers$, 300, " "
  addtostr ucase$(src$), nodes$, 300, " "
  select case token$
    case "PING"
      sendpacket "PONG from "+myself$, src$
    case "PONG"
      ' do nothing
    case else
      if dst$<>myself$ then 
        '  not only for me so, need to forward
        forward msg$, dst$, from$
      end if
      if (instr(groups$, dst$) <> 0) or (dst$=myself$) then 
        if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
          html "<tr><td>processpacket<td colspan=4>Destined for me, local processing needed.<td></tr>"
        end if
        lastmessage$=msg$
        ' destined to me
      end if
  end select
end sub

sub sendpacket(payload$, dst$)
  makepacket payload$, dst$
  if instr(payload$, "PINGG")=0 and instr(payload$, "PONG")=0 then
    html "<table border=1>"
    printpacket "sendpacket", payload$, dst$
'    html "</table>"
  end if
  forward payload$, dst$, ""
end sub

' msg$ = payload
' dst$ = node or group name or "broadcast"
' src$ = MAC of orginal sender
sub forward(msg$, dst$, src$)
  local i, peercount, peer$, node$, ttl
  local tmsgid$, tsrc$, tdst$, tttl$, tpayload$
  ttl$=ucase$(word$(msg$, 4, "|"))
  ttl=val(ttl$)
  ttl=ttl-1
  if ttl <= 0 then
    printpacket "forward TTL expired", payload$, dst$
  else
    tmsgid$  =word$(msg$, 1, "|")
    tsrc$    =ucase$(word$(msg$, 2, "|"))
    tdst$    =ucase$(word$(msg$, 3, "|"))
    tttl$    =str$(ttl)
    tpayload$=ucase$(word$(msg$, 5, "|"))
    msg$=tmsgid$+"|"+tsrc$+"|"+tdst$+"|"+tttl$+"|"+tpayload$
    if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
      printpacket "forward", msg$, dst$
    end if
    peercount=word.count(peers$)
    if ucase$(dst$)="BROADCAST" or peercount < 1 then
      espnow.add_peer("ff:ff:ff:ff:ff:ff")
      espnow.write(msg$)
      espnow.del_peer("ff:ff:ff:ff:ff:ff")
    else
      for i=1 to peercount
          peer$=word$(peers$, i)
          node$=word$(nodes$, i)
          if peer$<>src$ then  ' dont send back to the sender
              espnow.add_peer(peer$)
              espnow.write(msg$)
              espnow.del_peer(peer$)
                if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
                  html "<tr><td>forward<td colspan=4>sent to<td>"+node$+"("+peer$+")</tr>"
                end if
          else
              if instr(msg$, "PING")=0 and instr(msg$, "PONG")=0 then
                html "<tr><td>forward<td colspan=4>dont send back to sender<td>"+node$+"("+peer$+")</tr>"
              end if
          end if 
      next i
    end if 
    addtocache payload$
  end if
end sub

sub addtostr(what$, tostr$, maxlen, delim$)
  if instr(tostr$, what$) = 0 then
    if tostr$ = "" then
        tostr$=what$
    else
        tostr$=tostr$+delim$+what$
    end if
    tostr$=left$(tostr$, maxlen)
  end if
end sub

sub printlog(logstr$)
  wlog logstr$
  html "<br>"+replace$(logstr$, " ", "&nbsp")
end sub

message:
  msg$(wptr) = espnow.read$
  from$(wptr) = espnow.remote$
  wptr=(wptr+1) and 31
  return
  
  
status:
  printlog "TX error on "+ espnow.error$  ' print the error
  print "TX error on "+ espnow.error$  ' print the error
  return

  

