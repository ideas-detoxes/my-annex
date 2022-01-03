url$=word$(ip$, 3)+"/api/mkdir/"+word$(ip$, 1)
print url$
resp$=wget$(url$, 8080)
print resp$

url$=word$(ip$, 3)+"/api/ls/"+word$(ip$, 1)
print url$
resp$=wget$(url$, 8080)
print resp$
end
print "----GET FILES----"
for i= 1 to word.count(resp$)
  filename$=word$(resp$, i)
  url$=word$(ip$, 3)+"/api/download/"+filename$
  wlog url$
  file$=wget$(url$, 8080)
  fn$=word$(filename$, word.count(filename$, "/"), "/")
  wlog fn$
  file.save "/"+fn$, file$
next
print "files downloaded"
print "Starting /app.bas"
result = bas.load "/app.bas"
print result
