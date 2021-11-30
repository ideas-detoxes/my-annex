' msgid|src     |dst|payload
'  0509|node_200|any|Hello from node_200
msg$=""
from$=""
peers$=""
cache$="xXx"
nodes$=""
myself$="node-"+word$(WORD$(IP$,1),4,".")
groups$="any group1 group2"
msgid=millis mod 1000

menukey$=""
menu$=""
menu$=menu$+""+"1|Send to node 1|sendtonodex"
menu$=menu$+"@"+"2|Send to node 2|sendtonodex"
menu$=menu$+"@"+"3|Send to node 3|sendtonodex"
menu$=menu$+"@"+"4|Send to node 4|sendtonodex"
menu$=menu$+"@"+"5|Send to node 5|sendtonodex"
menu$=menu$+"@"+"6|Send to node 6|sendtonodex"
menu$=menu$+"@"+"a|Send to group Any|sendtogroupany"
menu$=menu$+"@"+"n|Print peer nodes|printnodes"
menu$=menu$+"@"+"q|Quit|quit"


onEspNowError status
onEspNowMsg message 
OnHtmlReload printmenu

espnow.begin
WIFI.APMODE "ESP="+myself$, "abrakadabra"


gosub printmenu 

do while 1
  if msg$ <> "" and from$ <> "" then
    html "<table border=1>"
    html "<tr><td>stage<td>msgid<td>from<td>to<td>payload<td>src/dst</tr>"
    printpacket "received", msg$, from$
'    printlog "RCV:"+msg$+"  F:"+from$
    processpacket msg$, from$
    html "</table>"
    msg$=""
    from$=""
  end if 
  c$=serial.chr$
  if c$<>"" then
    if c$=" " then
      gosub printmenu 
    endif
    if instr(menukey$, c$) <> 0 then
      gosub processmenu 
    end if
  end if
loop

end

processmenu:
  if c$="" then
   c$=left$(HtmlEventButton$,1)
  end if
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
  itemcnt=word.count(menu$, "@")
  for i=1 to itemcnt
    item$=word$(menu$, i, "@")
    print word$(item$, 1, "|")," - ";word$(item$,2,"|")
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
  peer=asc(c$) - asc("0")
  p$="Hello from "+myself$
  sendpacket p$, word$(nodes$, peer)
  print "Sending packet: ";p$
'  html "<br>Sending packet: " + p$
  return
sendtogroupany:
'  html "<br>send to all peers"
  p$="Hello from "+myself$
  print "Sending packet: ";p$
'  html "<br>Sending packet: " + p$
  sendpacket p$, "any"
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


while 1
  if msg$ <> "" and from$ <> "" then
    processpacket msg$, from$
  end if 
wend 

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
  local msgid$, src$, dst$, payload$, uniq$
'  printlog "processpacket M:"+msg$+" F:"+from$
  printpacket "processpacket", msg$, from$
  if word.count(msg$, "|") <> 4 then 
    exit sub 
  end if
  msgid$  =word$(msg$, 1, "|")
  src$    =word$(msg$, 2, "|")
  dst$    =word$(msg$, 3, "|")
  uniq$   =msgid$+src$
  if instr(cache$, uniq$) then 
    html "<tr><td>processpacket<td colspan=4>exist in cache<td></tr>"
'    printlog "    exists in cache"
    exit sub 
  end if
  addtocache msg$
  addtostr from$, peers$, 1000, " "
  addtostr src$, nodes$, 1000, " "
  if dst$<>myself$ then 
    forward msg$, from$
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
  forward payload$, "broadcast"
  html "</table>"
end sub

sub forward(msg$, from$)
  local i, peercount, peer$
'  printlog "forward: M:"+msg$+" F:"+from$
  printpacket "forward", msg$, from$
  peercount=word.count(peers$)
'  if peercount < 1 then ' now dont have peer, forward as broadcast
  if from$="broadcast" or peercount < 1 then
'    printlog "    as broadcast"
    espnow.add_peer("ff:ff:ff:ff:ff:ff")
    espnow.write(msg$)
    espnow.del_peer("ff:ff:ff:ff:ff:ff")
  else
    for i=1 to peercount
        peer$=word$(peers$, i)
        if peer$<>from$ then  ' dont send back to the sender
'            printlog "    send to:"+peer$
            espnow.add_peer(peer$)
            espnow.write(msg$)
            espnow.del_peer(peer$)
            html "<tr><td>forward<td colspan=4>sent to<td>"+peer$+"</tr>"
        else
            html "<tr><td>forward<td colspan=4>dont send back to sender<td>"+peer$+"</tr>"
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
  msg$  = espnow.read$
  from$ = ucase$(espnow.remote$)
  return

status:
  printlog "TX error on "; espnow.error$  ' print the error
  print "TX error on "; espnow.error$  ' print the error
  return

  
'§§
