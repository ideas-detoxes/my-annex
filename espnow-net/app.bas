x=99
x=espnow.begin
wlog "EspNow init:";x
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

myname$="Node_"+word$(word$(ip$, 1), 4, ".")
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
msgcnt=0
lastmsgtime=0
peers$=""

sendcycle=333
onEspNowError status
onEspNowMsg message 
timer0 sendcycle, sendtest

do while 1
  if rcvrptr<>rcvwptr then
    msg$=rq$(rcvrptr)
    rcvrptr=(rcvrptr+1) and mask
    if instr(cache$, left$(msg$, 8)) then 
      wlog "   exist in cache"
    else  
      addtoCache msg$
      process msg$
    end if  
  end if  
loop

sub getMac pkt$, pmac$
    pmac$ = word$(pkt$, 1, "|")
end sub
sub getSerial pkt$, serial$
    serial$ = word$(pkt$, 2, "|")
end sub
sub getCommand pkt$, pcommand$
    pcommand$ = word$(pkt$, 3, "|")
end sub 
sub getFrom pkt$, pfrom$
    pfrom$ = word$(pkt$, 4, "|")
end sub 
sub getTo pkt$, pto$
    pto$ = word$(pkt$, 5, "|")
end sub 
sub getRoute pkt$, route$
    route$ = word$(pkt$, 6, "|")
end sub 
sub getData pkt$, pdata$
    pdata$ = word$(pkt$, 6, "|")
end sub 
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
    'wlog "JoinPacket:";jppkt$
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
    'wlog "sendpacket:";spmac$, sppkt$
    espnow.add_peer(spmac$)
    espnow.write(sppkt$, spmac$)
    espnow.del_peer(spmac$)
end sub


message:
  message_tmp$=ucase$(espnow.remote$)+"|"+espnow.read$
  'wlog message_tmp$
  rq$(rcvwptr) = message_tmp$
  rcvwptr=(rcvwptr+1) and mask
  return
  
  
status:
  wloglog "TX error on "+ espnow.error$  ' wlog the error
  wlog "TX error on "+ espnow.error$  ' wlog the error
  return

sendtest:
    stpkt$=""
    joinpacket stpkt$, "X", "RM", myname$, "Node2", "X", "x"
    'wlog "Sending test messge:";stpkt$
    sendpacket stpkt$, 1
    'sub joinpacket(pkt$, mac$, command$, from$, to$, route$, data$)
return

sub process msg$
local tmp
local name$
local pmac$
    msgcnt=msgcnt+1
    wlog "Received", msg$, rcvrptr, rcvwptr, msgcnt, millis-lastmsgtime
    lastmsgtime = millis
    getFrom msg$, name$
    getMac msg$, pmac$
    if word.getparam$(peers$, name$) = "" then
        word.setparam peers$, name$, pmac$
    end if
end sub 

