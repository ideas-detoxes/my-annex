x=99
x=espnow.begin
wlog "EspNow init:";x
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

CRLF$=chr$(10)+chr$(13)

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
            processRcvMsg msg$
        end if  
    end if  
    if sndrptr<>sndwptr then
        msg$=sq$(sndrptr)
        sendpacket msg$
        sndrptr=(sndrptr+1) and mask
    end if
loop

sub delMac dmpmac$, dmpkt$
    dmpmac$=word$(dmpkt$, 1, "|")
    dmpkt$=word.delete$(dmpkt$, 1, "|")
end sub 

sub queuepacket(sppkt$, spbroadcast)
local spmac$
local message_tmp$
    addToCache sppkt$
    delMac spmac$, sppkt$
    if spbroadcast = 1 then
        spmac$="ff:ff:ff:ff:ff:ff"
    end if
    message_tmp$ = spmac$ + "|" + sppkt$
'wlog "QP:" + sppkt$ + " --> " + message_tmp$
    sq$(sndwptr) = message_tmp$
    sndwptr=(sndwptr+1) and mask
end sub

sub sendpacket(sppkt$)
local spmac$
    delMac spmac$, sppkt$
'wlog "sendpacket:";spmac$, sppkt$
    espnow.add_peer(spmac$)
    espnow.write(sppkt$, spmac$)
    espnow.del_peer(spmac$)
end sub


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


sub addToCache(acpkt$)
local acmac$, acserial$, accommand$, acfrom$, acto$, acroute$, acdata$
    splitpacket acpkt$, acmac$, acserial$, accommand$, acfrom$, acto$, acroute$, acdata$
'sub splitpacket(sppkt$, spmac$, spserial$, spcommand$, spfrom$, spto$, sproute$, spdata$)
    cache$=left$(cache$+acserial$+accommand$+" ", 250)
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
        queuepacket stpkt$, 1
'        if myname$ = "Node_175" or myname$ = "Node_110"then
'            wlog "Sending test messge:";stpkt$
'        end if
    end if
    routingbroadcastindex = routingbroadcastindex + 1
    if routingbroadcastindex > word.count(peers$, chr$(10)) then
        routingbroadcastindex = 1
    end if
return

sub checkTopology(pfrom$, result)
    result = (word.find(mypeers$, fromname$, "|") > 0)
end sub 

sub processRcvMsg(sg$)
local topologyValid
local fromname$
local pmac$
local cmd$
    getFrom msg$, fromname$
    checkTopology fromname$, topologyValid
    if topologyValid then
        getMac msg$, pmac$
        getCommand msg$, cmd$
        if word.getparam$(peers$, fromname$) = "" then
            word.setparam peers$, fromname$, "0"+pmac$
        end if
        select case cmd$
            case "RE"   ' broadcased RoutingEntry
                processRE msg$
        end select
    end if
end sub 

sub processRE(msg$)
local tmp
local mypeer_entry$
local mypeer_name$
local mypeer_mac$
local gotpeer_entry$
local gotpeer_name$
local gotpeer_mac$
local pdata$
local ser$
local gothop, myhop
local fromname$
local pmac$
    getFrom msg$, fromname$
    getMac msg$, pmac$
    getData msg$, gotpeer_entry$
    getSerial msg$, ser$
    if myname$ = "Node_110" then
        'wlog "RoutingEntry received from:" + fromname$ + "(" + pmac$ + ") :" + gotpeer_entry$ + " >> " + ser$ + " " + str$(ramfree)
        wlog "Peers:"
        wlog peers$
    end if
    gotpeer_name$ = word$(gotpeer_entry$, 1, "=")
    gotpeer_mac$ = word$(gotpeer_entry$, 2, "=")
    mypeer_mac$ = word.getparam$(peers$, gotpeer_name$)
    mypeer_name$ = gotpeer_name$
    gothop = val(left$(gotpeer_mac$, 1))
    if mypeer_mac$ = "" then
        word.setparam peers$, gotpeer_name$, str$(gothop+1)+pmac$
    else
        myhop = val(left$(mypeer_mac$, 1))
        if gothop < myhop then
            word.setparam peers$, gotpeer_name$, str$(gothop+1)+pmac$
        end if 
    end if
end sub
