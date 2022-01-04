x=99
x=espnow.begin
wlog "EspNow init:";x
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

iplast=val(word$(word$(ip$, 1), 4, "."))
pause iplast
myname$="Node_"+str$(iplast, "%03.0f")
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
' nodename=hopcount:nodemac
' hopcount: 0-9 0 means direct peer

peers$=""

word.setparam peers$, myname$, "0"+mac$

routingbroadcastindex = 1
routingbroadcastitem$=""
sendcycle=1000
onEspNowError status
onEspNowMsg message 
timer0 sendcycle, sendtest

topology$=""
word.setparam topology$, "Node_110", "Node_175"
word.setparam topology$, "Node_175", "Node_110|Node_242"
word.setparam topology$, "Node_242", "Node_175|Node_252"
word.setparam topology$, "Node_252", "Node_242"
mypeers$ = word.getparam$(topology$, myname$)
wlog "T:" + topology$
wlog "MP:" +  mypeers$




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
    pcommand$ = ucase$(word$(pkt$, 3, "|"))
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
    routingbroadcastitem$ = word$(peers$, routingbroadcastindex, chr$(10))
    if len(routingbroadcastitem$) > 0 then
        joinpacket stpkt$, "X", "RE", myname$, "ALL", routingbroadcastitem$, routingbroadcastitem$
        'sub joinpacket(pkt$, mac$, command$, from$, to$, route$, data$)
        sendpacket stpkt$, 1
'        if myname$ = "Node_175" or myname$ = "Node_110"then
'            wlog "Sending test messge:";stpkt$
'        end if
    end if
    routingbroadcastindex = routingbroadcastindex + 1
    if routingbroadcastindex > word.count(peers$, chr$(10)) then
        routingbroadcastindex = 1
    end if
return

sub process msg$
local tmp
local mypeer_entry$
local mypeer_name$
local mypeer_mac$
local gotpeer_entry$
local gotpeer_name$
local gotpeer_mac$
local fromname$
local pmac$
local cmd$
local pdata$
local ser$
local gothop, myhop
    msgcnt=msgcnt+1
'    wlog "Received", msg$, rcvrptr, rcvwptr, msgcnt, millis-lastmsgtime
    lastmsgtime = millis
    getFrom msg$, fromname$
    getMac msg$, pmac$
    if myname$ = "Node_110" then 
        wlog "mypeers:" + mypeers$ + " from:" + fromname$
    end if
    if word.find(mypeers$, fromname$, "|") > 0 then
        if word.getparam$(peers$, fromname$) = "" then
            word.setparam peers$, fromname$, "0"+pmac$
        end if
        getCommand msg$, cmd$
        getData msg$, gotpeer_entry$
        getSerial msg$, ser$
        select case cmd$
            case "RE"   ' broadcased RoutingEntry
                if myname$ = "Node_110" then
                    wlog "RoutingEntry received from:" + fromname$ + "(" + pmac$ + ") :" + gotpeer_entry$ + " >> " + ser$ + " " + str$(ramfree)
                end if
                gotpeer_name$ = word$(gotpeer_entry$, 1, "=")
                gotpeer_mac$ = word$(gotpeer_entry$, 2, "=")
                mypeer_mac$ = word.getparam$(peers$, gotpeer_name$)
                mypeer_name$ = gotpeer_name$
                if myname$ = "Node_110" then
                    wlog "MPE " + mypeer_name$ + "=" + mypeer_mac$ + "  GPE " + gotpeer_name$ + "=" + gotpeer_mac$
                end if
                gothop = val(left$(gotpeer_mac$, 1))
                if mypeer_mac$ = "" then
                    word.setparam peers$, gotpeer_name$, str$(gothop+1)+pmac$
                else
                    myhop = val(left$(mypeer_mac$, 1))
                    if gothop < myhop then
                        word.setparam peers$, gotpeer_name$, str$(gothop+1)+pmac$
                    end if 
                end if
        end select
    end if
end sub 

