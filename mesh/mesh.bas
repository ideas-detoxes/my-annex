msg$ = ""
from$ = ""
nodes$ = ""
msgid=millis mod 1000
shortmac$=replace$(mac$, ":", "")
cachemax=100*16  ' header len=16, max entry count=100
cache$=""
iam$=word$(WORD$(IP$,1),4,".")
groups$="any group1"

onEspNowError status
onEspNowMsg message 
OnHtmlReload fillpage

espnow.begin
WIFI.APMODE "ESP=", "abrakadabra"

gosub fillpage


do while 1
  if msg$ <> "" then
    processpacket msg$, from$
    msg$= ""
    from$=""
  endif
loop

end

sub processpacket(p$, from$)
wlog "pp:", p$
wlog "pp: ", from$
  shortfrom$=ucase$(replace$(from$, ":", ""))
  uniq$=left$(p$, 16)
  if instr(cache$, uniq$) then
    html "<br> exist in cache"
    exit sub
  endif
  if instr(nodes$, shortfrom$) = 0 then
    if nodes$="" then
      nodes$ = shortfrom$
    else
      nodes$=nodes$+" "+shortfrom$
    endif
    espnow.add_peer(from$)
  endif
  cache$=left$(uniq$+cache$, cachemax)
  dst$=word$(p$, 2, "|")
  html "<br>cimzett: " + dst$
  x=word.count(groups$)
  groupmatch=0
  forme=0
  if dst$ = iam$ then
    forme=1
  endif
  for i=1 to x
    if word$(groups$, i) = dst$ then
      groupmatch=groupmatch+1
      forme=forme+1
    endif
  next
  if (groupmatch > 0) or (forme=0) then
    forwardpacket p$, shortfrom$
  endif
  if forme > 0 then
        userprocess p$
  endif
end sub

sub forwardpacket p$, f$
  cnt=word.count(nodes$)
  for i=1 to cnt
    n$=word$(nodes$, i)
    if n$ <> f$
      html "<br>    forwarding to: " + n$
    endif
  next
end sub

sub makepacket(payload$, dst$)
  payload$=str$(msgid, "%04.0f")+shortmac$+"|"+dst$+"|"+payload$
  msgid=msgid+1
  if msgid > 100 then
    msgid=1
  endif
end sub

sub doscan
  WIFI.SCAN
  While WIFI.NETWORKS(A$) = -1
  Wend
  lc = word.count(a$, chr$(10))
  for i = 1 to lc
    line$ = word$(a$, i, chr$(10))
    if word$(line$, 1, ",") = "ESP=" then
      nodes$ = nodes$ + replace$(word$(line$, 2, ","), ":", "") + " "
      espnow.add_peer(word$(line$, 2, ","))
    endif
  next i
  if nodes$ <> "" then
    nodes$=left$(nodes$, len(nodes$)-1)
  endif
end sub

sub userprocess(p$)
    html "<br>Valid packet received:  " + p$  
end sub
 
click:
  p$="Hello from "+iam$
  makepacket p$, HtmlEventButton$
  espnow.write(p$)
return


message:
  msg$  = espnow.read$
  from$ = espnow.remote$ 
  return

status:
  wlog "TX error on "; espnow.error$  ' print the error
  return


fillpage:
msg$ = ""
from$ = ""
nodes$ = ""
cls
html "Scanning"
doScan
cls
a$= "Scanning done, peers:<br>"
for i=1 to word.count(nodes$)
  a$=a$+word$(nodes$, i) + "<br>"
next i
a$=a$+button$("140", click)+"   "
a$=a$+button$("190", click)+"   "
a$=a$+button$("251", click)+"   "
a$=a$+button$("200", click)+"   "
a$=a$+button$("any", click)+"   "
a$=a$+button$("group1", click)+"   "
a$=a$+button$("group2", click)+"   "
a$=a$+"<br>"
'a$=a$+"<input type='text'id='txbox' value='---------------------------------'>"
html a$
return
'§§
