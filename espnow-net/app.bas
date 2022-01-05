x=99
x=espnow.begin
wlog "EspNow init:";x
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"

global_dummy = 0
CRLF$=chr$(10)+chr$(13)
BROADCAST_MAC$="ff:ff:ff:ff:ff:ff"
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
serial=1
msgcnt=0
lastmsgtime=0
' nodename=hopcount:nodemac
' hopcount: 0-9 0 means myself and direct peers

deadtimers$ = ""
peers$=""
oneSecondFlag = 1
secondCounter = 0
word.setparam peers$, myname$, "0"+mac$

sendRoutesindex=1
onEspNowError status
onEspNowMsg message 
timer0 1000, oneSecondLbl

topology$=""
word.setparam topology$, "Node_110", "Node_175|Node_242"
word.setparam topology$, "Node_175", "Node_110|Node_252"
word.setparam topology$, "Node_242", "Node_110|Node_252"
word.setparam topology$, "Node_252", "Node_175|Node_242"
mypeers$ = word.getparam$(topology$, myname$)
logger "T:" + topology$
logger "MP:" +  mypeers$

mainloop global_dummy
wait 

sub mainloop(dummy)
local cmd$
    do while 1
        do while rcvrptr<>rcvwptr 
            msg$=rq$(rcvrptr)
            rcvrptr=(rcvrptr+1) and mask
            if instr(cache$, left$(msg$, 8)) then 
                logger "   exist in cache"
            else  
                getCommand msg$, cmd$
                if instr(cmd$, "-ACK") = 0 then
                    addtoCache msg$
                end if
                processRcvMsg msg$
            end if  
        loop 
        do while sndrptr<>sndwptr 
            msg$=sq$(sndrptr)
            transmitpacket msg$
            sndrptr=(sndrptr+1) and mask
        loop 
        if oneSecondFlag = 1 then
            oneSecondFlag = 0
            oneSecond global_dummy
        end if
    loop
end sub

sub logger(txt$)
    wlog txt$
    print txt$
end sub

sub delMac dmpkt$, dmpmac$
    dmpmac$=word$(dmpkt$, 1, "|")
    dmpkt$=word.delete$(dmpkt$, 1, "|")
end sub 

sub queuepacket(sppkt$)
    addToCache sppkt$
    sq$(sndwptr) = sppkt$
    sndwptr=(sndwptr+1) and mask
end sub

sub transmitpacket(sppkt$)
local spmac$
    delMac sppkt$, spmac$
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
sub getData pkt$, pdata$
    pdata$ = word$(pkt$, 6, "|")
end sub 
sub splitpacket(sppkt$, spmac$, spserial$, spcommand$, spfrom$, spto$, spdata$)
' MAC|SERIAL|COMMAND|ORIGINATOR_NAME|DESTINATION_NAME|DATA
    spmac$     = word$(sppkt$, 1, "|")
    spserial$  = word$(sppkt$, 2, "|")
    spcommand$ = word$(sppkt$, 3, "|")
    spfrom$    = word$(sppkt$, 4, "|")
    spto$      = word$(sppkt$, 5, "|")
    spdata$    = word$(sppkt$, 6, "|")
end sub

sub joinPacket(jppkt$, jpmac$, jpcommand$, jpfrom$, jpto$, jpdata$)
' MAC|SERIAL|COMMAND|ORIGINATOR_NAME|DESTINATION_NAME|DATA
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
    jppkt$ = jppkt$ + "|" + jpdata$
    'logger "JoinPacket:";jppkt$
end sub


sub addToCache(acpkt$)
local acserial$, accommand$
'    splitpacket acpkt$, acmac$, acserial$, accommand$, acfrom$, acto$, acdata$
    getSerial acpkt$, acserial$
    getCommand acpkt$, accommand$
    cache$=left$(cache$+acserial$+accommand$+" ", 250)
end sub 



message:
  message_tmp$=ucase$(espnow.remote$)+"|"+espnow.read$
  'logger message_tmp$
  rq$(rcvwptr) = message_tmp$
  rcvwptr=(rcvwptr+1) and mask
  return
  
sub deletePeer(pmac$)  
local cnt
local i
local wc
    cnt = 1
    do while cnt > 0
        cnt = 0
        wc = word.count(peers$, chr$(10))
        if wc > 0
            for i = 1 to wc
                if instr(word$(peers$, i, chr$(10)), pmac$) <> 0 then
                    if cnt = 0 then
                        cnt = cnt + 1
                        peers$ = word.delete$(peers$, i, chr$(10))
                    end if
                end if
            next
        end if
    loop
end sub

status:
    espnow_error$ = ucase$(espnow.error$)
    logger  "TX error on "+ espnow_error$  ' logger the error
    deletePeer "0"+espnow_error$
return

sub sendRoutes(dummy)
local pkt$
local item$
    pkt$=""
    item$ = word$(peers$, sendRoutesindex, chr$(10))
    if len(item$) > 0 then
        joinPacket pkt$, BROADCAST_MAC$, "RE", myname$, "ALL", item$
        'sub joinPacket(pkt$, mac$, command$, from$, to$, data$)
        queuepacket pkt$
'        if myname$ = "Node_175" or myname$ = "Node_110"then
'            logger "Sending route update:";pkt$
'        end if
    end if
    sendRoutesindex = sendRoutesindex + 1
    if sendRoutesindex > word.count(peers$, chr$(10)) then
        sendRoutesindex = 1
    end if
end sub

sub oneSecond(dummy)
local ts
local age
local i
local item$
local pmac$
local its$
    sendRoutes dummy
    secondCounter = secondCounter + 1
    if (secondCounter mod 3)  = 0 then
        if myname$ = "Node_110" then
            sendMessage "Node_252", str$(millis)
        end if
    end if
    if (secondCounter mod 5)  = 0 then
'        word.setparam deadtimers$, pmac$, str$(millis)
        ts = millis
        deletes$ = ""
        wc = word.count(deadtimers$, chr$(10))
        if wc > 0 then
            if myname$ = "Node_110" then
                logger "-----------5sec begin"
                logger str$(ts)
                logger "deadtimers:"
                logger deadtimers$
                logger "peers:"
                logger peers$
            end if
            if myname$ = "Node_110" then
                logger "---------processing"
            end if
            for i=1 to wc
                item$ = word$(deadtimers$, i, chr$(10))
                if len(item$) > 0 then
                    pmac$ = word$(item$, 1, "=")
                    its$ = word$(item$, 2, "=")
                    age = ts - val(its$)
                    if myname$ = "Node_110" then
                        logger "...................." + item$ + " " + str$(len(item$)) + " " + pmac$ + " " + its$ + " " + str$(ts)  + " " + str$(age)
                    end if
                    if age > 5000 then
                        deletePeer "0"+pmac$
                    end if
                end if
            next 
            if myname$ = "Node_110" then
                logger "deadtimers:"
                logger deadtimers$
                logger "peers:"
                logger peers$
                logger "-----------5sec END"
            end if
        end if
    end if
end sub

oneSecondLbl:
    oneSecondFlag = 1
return

sub checkTopology(pfrom$, pcmd$, result)
    if pcmd$ = "RE" then
        result = (word.find(mypeers$, fromname$, "|") > 0)
    else
        result = (1=1)
    end if
end sub 

sub processRcvMsg(sg$)
local topologyValid
local fromname$
local toname$
local pmac$
local cmd$
local sended$
    getFrom msg$, fromname$
    getCommand msg$, cmd$
    getMac msg$, pmac$
    checkTopology fromname$, cmd$, topologyValid
    if topologyValid then
        if word.getparam$(peers$, fromname$) = "" then
            word.setparam peers$, fromname$, "0"+pmac$
        end if
        word.setparam deadtimers$, pmac$, str$(millis)
        if cmd$ = "RE" then
            processRE msg$
        end if
        if cmd$ = "MSG" or cmd$ = "MSG-ACK" then
            getTo msg$, toname$
            if toname$ <> myname$ then
                forwardMessage msg$
            else
                if cmd$ = "MSG" then
'                    logger "Message for me :" + msg$ 
                    sendAck msg$
                end if
                if cmd$ = "RE-ACK" then
                end if
                if cmd$ = "MSG-ACK" then
                    getData msg$, sended$
                    logger "MSG-ACK received   :" + msg$ + " RTT:" + str$(millis - val(sended$))
                end if
            end if
        end if
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
'        logger "RoutingEntry received:" + msg$
        'logger "RoutingEntry received from:" + fromname$ + "(" + pmac$ + ") :" + gotpeer_entry$ + " >> " + ser$ + " " + str$(ramfree)
'        logger "Peers:"
'        logger peers$
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
    sendAck msg$
end sub


sub sendMessage(pto$, pdata$)
local stpkt$
local nexthop$
local via$
local i
    nexthop$ = word.getparam$(peers$, pto$)
    via$ = "VIA"
    for i = 1 to word.count(peers$, chr$(10))
        if instr(word$(peers$, i, chr$(10)), "0"+mid$(nexthop$, 2)) > 0 then
            via$=word$(peers$, i, chr$(10))
        end if
    next 
    if nexthop$ = "" then
        logger "No route to       : " + pto$
    else
        nexthop$ = mid$(nexthop$, 2)
        joinPacket stpkt$, nexthop$, "MSG", myname$, pto$, pdata$
        queuepacket stpkt$
        logger "Sended         :" + stpkt$ + " Via:" + via$
    end if
end sub 

sub forwardMessage(msg$)
local pto$
local nexthop$
local tmp$
local msgtmp$
    msgtmp$ = msg$
'    logger ">>"
'    logger "Forwarding:       " + msgtmp$
    getTo msg$, pto$
    nexthop$ = word.getparam$(peers$, pto$)
    if nexthop$ = "" then
'        logger "No route to      : " + pto$
    else
        nexthop$ = mid$(nexthop$, 2)
        delMac msgtmp$, tmp$
        msgtmp$ = nexthop$ + "|" + msgtmp$
        queuepacket msgtmp$
'        logger "Forwarding      : " + msgtmp$ + " via: " + nexthop$
    end if
'    logger "<<"
end sub

sub sendAck(pmsg$)
local ackpkt$
local nexthop$
local pto$
local pfrom$
local ackdata$
local serial$
local cmd$
    getFrom pmsg$, pfrom$
    getTo pmsg$, pto$
    getData pmsg$, ackdata$
    getCommand pmsg$, cmd$
    cmd$ = cmd$ + "-ACK"
    nexthop$ = word.getparam$(peers$, pfrom$)
    if nexthop$ = "" then
'        logger "ACK No route to:" + pfrom$
    else
        getSerial pmsg$, serial$
        nexthop$ = mid$(nexthop$, 2)
        joinPacket ackpkt$, nexthop$, cmd$, myname$, pfrom$, ackdata$
        queuepacket ackpkt$
'        logger "ACK sended to  :"  + ackpkt$ 
    end if
end sub 
