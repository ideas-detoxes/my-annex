test=1
myself$=ucase$("node-"+word$(WORD$(IP$,1),4,"."))


'"NODE-140  82:7D:3A:47:62:20"
'"NODE-190  B6:E6:2D:13:F3:07"
'"NODE-200  5E:CF:7F:1A:FD:24"
'"NODE-251  B6:E6:2D:13:F3:44"
  select case myself$
    case "NODE-140"
      allowedpeers$="B6:E6:2D:13:F3:07"
      allowednodes$="NODE-190 NODE-200 NODE-251"
    case "NODE-190"
      allowedpeers$="82:7D:3A:47:62:20 5E:CF:7F:1A:FD:24"
      allowednodes$="NODE-140 NODE-200 NODE-251"
    case "NODE-200"
      allowedpeers$="B6:E6:2D:13:F3:07 B6:E6:2D:13:F3:44"
      allowednodes$="NODE-140 NODE-190 NODE-251"
    case "NODE-251"
      allowedpeers$="5E:CF:7F:1A:FD:24"
      allowednodes$="NODE-140 NODE-190 NODE-200"
  end select


' msgid|src     |dst|payload
'  0509|node_200|any|Hello from node_200
msg$=""
from$=""
cache$="xXx"
nodes$=""
peers$=""
groups$=ucase$("any group1 group2")
msgid=millis mod 1000

count=64
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
'menu$=menu$+""+"1|Send to node 1|sendtonodex"
'menu$=menu$+"@"+"2|Send to node 2|sendtonodex"
'menu$=menu$+"@"+"3|Send to node 3|sendtonodex"
'menu$=menu$+"@"+"4|Send to node 4|sendtonodex"
'menu$=menu$+"@"+"5|Send to node 5|sendtonodex"
'menu$=menu$+"@"+"6|Send to node 6|sendtonodex"
menu$=menu$+"@"+"a|Send to group Any|sendtogroupany"
menu$=menu$+"@"+"n|Print peer nodes|printnodes"
menu$=menu$+"@"+"q|Quit|quit"


onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu

espnow.begin
'WIFI.APMODE "ESP="+myself$, "abrakadabra"
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"


gosub printmenu 

do while 1
  if test=1 then
    peers$=allowedpeers$
    nodes$=allowednodes$
  end if
  if rptr<>wptr then
    msg$=msg$(rptr)
    from$=ucase$(from$(rptr))
    rptr=(rptr+1) and 63
    flag=0
    if test=0 then flag=flag+1
    if test=1 and instr(allowedpeers$, from$)>0 then flag=flag+1
    if flag > 0 then
      html "<table border=1>"
      html "<tr><td>stage<td>msgid<td>from<td>to<td>payload<td>src/dst</tr>"
      printpacket "received", msg$, from$
  '    printlog "RCV:"+msg$+"  F:"+from$
      processpacket msg$, from$
      html "</table>"
      msg$=""
      from$=""
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
  itemcnt=word.count(menu$, "@")
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
'    print word$(item$, 1, "|")," - ";word$(item$,2,"|")
    h$=h$+ "<br>"
    h$=h$+ button$(word$(item$, 1, "|") + "---" + word$(item$,2,"|"), processmenu)
    menukey$=menukey$+word$(item$, 1, "|")
  next i
  html h$
return

help:
  return

sendtonodex:
'  print "Send to peer X"
  html "<br>send to peer:" + c$
  for ii=1 to 1
  p$="Hello from "+myself$
    node=asc(c$) - asc("0")
    sendpacket p$, word$(nodes$, node)
  next
'  html "<br>Sending packet: " + p$
  return
sendtogroupany:
'  html "<br>send to all peers"
  for ii=1 to 1
    p$="Hello from "+myself$
'    print "Sending packet: ";p$
    sendpacket p$, "any"
  next
  return
printpeers:
  print "Current MACs of peers:"
  html "<table border=1>"
  for i=1 to word.count(peers$)
    print i, word$(peers$, i)
    html "<tr><td>"+str$(i) + "<td>" +  word$(peers$, i) + "<tr>"
  next i
  html "</table>"
  return
printnodes:
  print "Current peer nodes:"
  html "<table border=1>"
  for i=1 to word.count(nodes$)
    print i, word$(nodes$, i)
    html "<tr><td>"+str$(i) + "<td>" +  word$(nodes$, i) + "<td>"+word$(peers$, i)+"<tr>"
  next i
  html "</table>"
  return

sub printpacket(pre$, pkt$, frm$)
  local msgid$, src$, dst$, payload$, h$
  msgid$  =word$(pkt$, 1, "|")
  src$    =word$(pkt$, 2, "|")
  dst$    =word$(pkt$, 3, "|")
  payload$=word$(pkt$, 4, "|")
'  h$="<table border=1><tr><td>"+pre$+"<td>"+msgid$+"<td>"+src$+"<td>"+dst$+"<td>"+payload$+"<td>"+frm$+"</table>"
  h$="<tr><td>"+pre$+"<td>"+msgid$+"<td>"+src$+"<td>"+dst$+"<td>"+payload$+"<td>"+frm$+"</tr>"
  html h$
end sub
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''



sub addtocache(msg$)
  local msgid$, src$, dst$, payload$, uniq$
  msgid$  =word$(msg$, 1, "|")
  src$    =word$(msg$, 2, "|")
  dst$    =word$(msg$, 3, "|")
  payload$=word$(msg$, 4, "|")
  uniq$   =msgid$+src$
  addtostr uniq$, cache$, 3000, ""
end sub 

sub makepacket(payload$, dst$)
  payload$=str$(msgid, "%04.0f")+"|"+myself$+"|"+dst$+"|"+payload$
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  end if
end sub

sub processpacket(msg$, from$)
  local msgid$, src$, dst$, payload$, uniq$, i, tmp
'  printlog "processpacket M:"+msg$+" F:"+from$
  printpacket "processpacket", msg$, from$
  if word.count(msg$, "|") <> 4 then 
    exit sub 
  end if
  msgid$  =word$(msg$, 1, "|")
  src$    =ucase$(word$(msg$, 2, "|"))
  dst$    =ucase$(word$(msg$, 3, "|"))
  uniq$   =ucase$(msgid$+src$)
  if instr(cache$, uniq$) then 
    html "<tr><td>processpacket<td colspan=4>exist in cache<td></tr>"
'    printlog "    exists in cache"
    exit sub 
  end if
  addtocache msg$
  addtostr ucase$(from$), peers$, 1000, " "
  addtostr ucase$(src$), nodes$, 1000, " "
  if dst$<>myself$ then 
    '  not only for me so, need to forward
    tmp=millis mod 30
    for i=1 to tmp
    next i
    forward msg$, dst$, from$
  end if
  if (instr(groups$, dst$) <> 0) or (dst$=myself$) then 
    html "<tr><td>processpacket<td colspan=4>Destined for me, local processing needed.<td></tr>"
'    printlog "    Destined for me, local processing needed."
    ' destined to me
  end if
end sub

sub sendpacket(payload$, dst$)
  html "<table border=1>"
  makepacket payload$, dst$
'  printlog "sendpacket: M:"+payload$+" D:"+dst$
  printpacket "sendpacket", payload$, dst$
  forward payload$, "broadcast", ""
  html "</table>"
end sub

sub forward(msg$, dst$, src$)
  local i, peercount, peer$, node$
'  printlog "forward: M:"+msg$+" F:"+from$
  printpacket "forward", msg$, dst$
  peercount=word.count(peers$)
'  if peercount < 1 then ' now dont have peer, forward as broadcast
  if dst$="broadcast" or peercount < 1 then
'    printlog "    as broadcast"
    espnow.add_peer("ff:ff:ff:ff:ff:ff")
    espnow.write(msg$)
    espnow.del_peer("ff:ff:ff:ff:ff:ff")
  else
    for i=1 to peercount
        peer$=word$(peers$, i)
        node$=word$(nodes$, i)
        if peer$<>src$ then  ' dont send back to the sender
'            printlog "    send to:"+peer$
            espnow.add_peer(peer$)
            espnow.write(msg$)
            espnow.del_peer(peer$)
            html "<tr><td>forward<td colspan=4>sent to<td>"+node$+"("+peer$+")</tr>"
        else
            html "<tr><td>forward<td colspan=4>dont send back to sender<td>"+node$+"("+peer$+")</tr>"
'          printlog "    dont send back to sender"
        end if 
    next i
  end if 
  addtocache payload$
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
  print logstr$
  wlog logstr$
  html "<br>"+replace$(logstr$, " ", "&nbsp")
end sub

message:
  msg$(wptr) = espnow.read$
  from$(wptr) = espnow.remote$
  wptr=(wptr+1) and 63
  return
  
  
status:
  printlog "TX error on "; espnow.error$  ' print the error
  print "TX error on "; espnow.error$  ' print the error
  return

  
'§§
