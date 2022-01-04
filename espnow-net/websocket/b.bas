wlog ip$
for i=1 to 99999
  logstr$="Test bas file"+" " + word$(ip$, 1)+" " + time$
  print logstr$
  wlog logstr$
  pause 333
next
wait

