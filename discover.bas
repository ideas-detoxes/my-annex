

myName$=ucase$("node-"+word$(WORD$(IP$,1),4,"."))
myMAC$=mac$(1)
onEspNowError status
onEspNowMsg message 

peerTable$=""
DNS$=""
reverseDNS$=""
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
  end if
  if millis > discovertime then
    discovertime=millis+100
    espnow.write(peerTable$)
  end if
wend



sub espNowReceive(msg$, from$)
local nodeName$, peers$, i, tmp$, mypeers$
' msg$ ini file formatumban tartamazza 
' a felado altal ismert node-okat
' (a felado a peeerTable$-t kuldi)
  for i=1 to word.count(msg$, chr$(10))
    ' sorokra bontjuk
    tmp$=word$(msg$, i, chr$(10))
    nodeName$=word$(tmp$, 1, "=")
    peers$=word.getparam$(tmp$, nodeName$)
    mypeers$ = word.getparam$(peerTable$, myName$)
    if instr(mypeers$, from$)=0 then
      ' ha a kuldo meg nem szerepel a sajat peer-ek kozott
      word.setparam peerTable$, myName$, trim$(word.getparam$(peerTable$, myName$) + " " + from$)
    end if
    if nodeName$<>myName$ and nodeName$<>"" then
      ' ha nem az en sorom a peer tablajaban
      word.setparam peerTable$, nodeName$, peers$
      word.setparam DNS$, nodeName$, from$
      word.setparam reverseDNS$, from$, nodeName$
    end if
  next
end sub


message:
  espNowReceive ucase$(espnow.read$), ucase$(espnow.remote$)
  return
  
  
status:
  wlog "TX error on "+ espnow.error$  ' print the error
  return
