


x=99
x=espnow.begin
print "EspNow init:";x
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

rcvwptr=0
rcvrptr=0
sndwptr=0
sndrptr=0
count=32
mask=count-1
dim rq$(count)
dim sq$(count)
cache$="xXx"
routes$=""
serial=1

onEspNowError status
onEspNowMsg message 
timer0 33, sendtest

do while 1
  if rcvrptr<>rcvwptr then
    msg$=rq$(rcvrptr)
    rcvrptr=(rcvrptr+1) and mask
    print "Received", msg$, rcvrptr, rcvwptr
    if instr(cache$, left$(msg$, 8)) then 
      print "   exist in cache"
    else  
      addtoCache msg$
      process msg$
    end if  
  end if  

loop


sub splitpacket(sppkt$, spmac$, spserial$, spcommand$, spfrom$, spto$, sproute$, spdata$)
' MAC|SERIAL|COMMAND|ORIGINATOR_NAME|DESTINATION_NAME|ROUTE|DATA
    spmac$     = word$(sppkt$, 1, "|")
    spserial$  = word$(sppkt$, 2, "|")
    spcommand$ = word$(sppkt$, 3, "|")
    spfrom$    = word$(sppkt$, 4, "|")
    spto$      = word$(sppkt$, 5, "|")
    sproute$   = word$(sppkt$, 6, "|")
    spdata$    = word$(sppkt$, 7, "|")
end sub

sub joinpacket(jppkt$, jpmac$, jpcommand$, jpfrom$, jpto$, jproute$, jpdata$)
' MAC|SERIAL|COMMAND|ORIGINATOR_NAME|DESTINATION_NAME|ROUTE|DATA
'  17|  4   |   4   |               |                |     |
    serial=serial+1
    if serial > 9999 then
        serial = 1
    end if
    jpserial$=str$(serial, "%04.0f")
    jppkt$ = jpmac$
    jppkt$ = jppkt$ + "|" + jpserial$
    jppkt$ = jppkt$ + "|" + jpcommand$
    jppkt$ = jppkt$ + "|" + jpfrom$
    jppkt$ = jppkt$ + "|" + jpto$
    jppkt$ = jppkt$ + "|" + jproute$
    jppkt$ = jppkt$ + "|" + jpdata$
    'print "JoinPacket:";jppkt$
end sub

sub delmac dmpmac$, dmpkt$
    dmpmac$=word$(dmpkt$, 1, "|")
    dmpkt$=word.delete$(dmpkt$, 1, "|")
end sub 

sub addToCache(acpkt$)
local acmac$, acserial$, accommand$, acfrom$, acto$, acroute$, acdata$
    splitpacket acpkt$, acmac$, acserial$, accommand$, acfrom$, acto$, acroute$, acdata$
'sub splitpacket(sppkt$, spmac$, spserial$, spcommand$, spfrom$, spto$, sproute$, spdata$)
    cache$=left$(cache$+acserial$+accommand$+" ", 250)
end sub 

sub sendpacket(sppkt$, spbroadcast)
local spmac$
    addToCache sppkt$
    spmac$=""
    delmac spmac$, sppkt$
    if spbroadcast = 1 then
        spmac$="ff:ff:ff:ff:ff:ff"
    end if
    'print "sendpacket:";spmac$, sppkt$
    espnow.add_peer(spmac$)
    espnow.write(sppkt$, spmac$)
    espnow.del_peer(spmac$)
end sub


message:
  message_tmp$=ucase$(espnow.remote$)+"|"+espnow.read$
  'print message_tmp$
  rq$(rcvwptr) = message_tmp$
  rcvwptr=(rcvwptr+1) and mask
  return
  
  
status:
  printlog "TX error on "+ espnow.error$  ' print the error
  print "TX error on "+ espnow.error$  ' print the error
  return

sendtest:
    stpkt$=""
    joinpacket stpkt$, "X", "RM", "Node1", "Node2", "X", "TestMessage"
    'print "Sending test messge:";stpkt$
    sendpacket stpkt$, 1
    'sub joinpacket(pkt$, mac$, command$, from$, to$, route$, data$)
return

sub process msg$
end sub 

