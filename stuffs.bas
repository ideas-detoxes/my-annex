'WIFI.SLEEP
'pause 5000
'WIFI.AWAKE
WIFI.APMODE "MESH", "abrakadabralksd89usadn,msc8u9usd"
espnow.begin
onEspNowError status
onEspNowMsg message 
OnHtmlReload reload

msgq_rp=0
msgq_wp=0
msgq_size=10
dim frmq$(msgq_size)
dim msgq$(msgq_size)


text$="Hello bello volna egy kis melo!"

cls


wait


sub getMessage(frm$, msg$)
  frm$=ucase$(frmq$(msgq_rp))
  msg$=msgq$(msgq_rp)
  msgq_rp=msgq_rp+1
  if msgq_rp>msgq_size then 
    msgq_rp=0
  end if
end sub

message:
  msgq$(msgq_wp)=espnow.read$
  frmq$(msgq_wp)=espnow.remote$
  msgq_wp=msgq_wp+1
  if msgq_wp>msgq_size then 
    msgq_wp=0
  endif
  return

status:
  print "TX error on "; espnow.error$  ' print the error
  return

reload:
  cls
  HTML TEXTBOX$(text$)
  text$=text$+text$+chr$(13)+chr$(13)+"almafa"
  HTML TEXTAREA$(text$)
reload1:
  html "------------------------------<br><table border=1>"
  for i=0 to msgq_size
    f$=""
    if i=msgq_rp then
      f$=f$+"R"
    endif
    if i=msgq_wp then
      f$=f$+"W"
    endif
    html "<tr><td>"+f$+"<td>"+str$(i)+"<td>"+frmq$(i)+"<td>"+msgq$(i)
  next i
  html "</table>"
return

