

myName$=ucase$("node-"+word$(WORD$(IP$,1),4,"."))
myMAC$=mac$(1)
onEspNowError status
onEspNowMsg message 

peerTable$=""
DNS$=""
nodePeers$=""
word.setparam peerTable$, myName$, myMAC$
word.setparam DNS$, myName$, myMAC$
word.setparam reverseDNS$, myMAC$, myName$

word.setparam peerTable$, myName$, ucase$(mac$(1))

espnow.begin
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"
espnow.add_peer("ff:ff:ff:ff:ff:ff")

discovertime=millis+100
acttime=millis+3000
a$="xx"
while 1=1
  if millis > acttime then
    acttime=millis+5000
    resolvePeerTable 
    computeDFS
'    wlog nodePeers$
  end if
  if millis > discovertime then
    discovertime=millis+100
    espnow.write(peerTable$)
  end if
wend



sub espNowReceive(msg$, from$)
local nodeName$, peers$, i, line$, mypeers$
'wlog "RCV:"
'wlog msg$
'wlog from$
' msg$ ini file formatumban tartamazza 
' a felado altal ismert node-okat
' (a felado a peeerTable$-t kuldi)
  mypeers$ = word.getparam$(peerTable$, myName$)
  if instr(mypeers$, from$)=0 then
  ' ha a kuldo meg nem szerepel a sajat 
  ' peer-ek kozott, akkor hozzáadjuk a mar meglevo listahoz
    word.setparam peerTable$, myName$, trim$(mypeers$ + " " + from$)
  end if
  for i=1 to word.count(msg$, chr$(10))
    ' a kapott tablat sorokra bontjuk
    line$=word$(msg$, i, chr$(10))
    nodeName$=word$(line$, 1, "=") 
    peers$=word.getparam$(line$, nodeName$)
    if nodeName$<>myName$ and nodeName$<>"" then
      ' ha nem az en sorom a peer tablajaban
      word.setparam peerTable$, nodeName$, peers$
    end if
  next
end sub

sub updateDNS
local i, line$, tmp$, name$, macc$
  for i=1 to word.count(peerTable$, chr$(10))
    line$=word$(peerTable$, i, chr$(10))
    tmp$=word$(line$, 1)
    name$=word$(tmp$, 1, "=")
    macc$=word$(tmp$, 2, "=")
    if name$<>"" then
      word.setparam DNS$, name$, macc$
    end if
  next
'  wlog DNS$
end sub

sub resolvePeerTable
  local dnsline$, name$, peermac$, i
  updateDNS
  nodePeers$=peerTable$
  for i=1 to word.count(DNS$, chr$(10))
    dnsline$=word$(DNS$, i, chr$(10))
    name$=word$(dnsline$, 1, "=")
    peermac$=word$(dnsline$, 2, "=")
    nodePeers$=replace$(nodePeers$, peermac$, name$)
  next i
  wlog nodePeers$
end sub

message:
  espNowReceive ucase$(espnow.read$), ucase$(espnow.remote$)
  return
  
  
status:
  wlog "TX error on "+ espnow.error$  ' print the error
  return


sub dfs(network$, start$, result$)
local visited$
  visited$=""
  dfs_int network$, visited$, start$
  result$=visited$
end sub

sub dfs_int(network$, visited$, node$)
local tmp$, i, neighbour$
     if instr(visited$, node$)=0 then
         visited$=visited$+" "+node$
         tmp$=word.getparam$(network$, node$)
         for i=1 to len(tmp$)
             neighbour$=word$(tmp$, i)
            dfs_int network$, visited$, neighbour$
         next
     end if'
end sub



sub computeDFS
  wlog "Following is the Depth-First Search"
  dfs$=""
  dfs nodePeers$, myName$, dfs$
  wlog "result:", dfs$
end sub