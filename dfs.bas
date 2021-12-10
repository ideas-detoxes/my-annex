  network$=""
  word.setparam network$, "A", "B"
  word.setparam network$, "B", "D E F"
  word.setparam network$, "C", "B D"
  word.setparam network$, "D", "C E A"
  word.setparam network$, "E", "D F"
  word.setparam network$, "F", "E"
  wlog network$


'NODE-115=4A:3F:DA:77:9F:4B B6:E6:2D:13:F3:07 5E:CF:7F:1A:FD:24
'NODE-190=B6:E6:2D:13:F3:07 4A:3F:DA:77:9F:4B 5E:CF:7F:1A:FD:24
'NODE-200=5E:CF:7F:1A:FD:24 B6:E6:2D:13:F3:07 4A:3F:DA:77:9F:4B

sub dfs(network$, start$, result$)
local visited$
  visited$=""
  dfs_int network$, visited$, start$
  result$=visited$
end sub

sub dfs_int(network$, visited$, node$)
local tmp$, i, neighbour$
     if instr(visited$, node$)=0 then
         visited$=visited$+" "+node$
         tmp$=word.getparam$(network$, node$)
         for i=1 to len(tmp$)
             neighbour$=word$(tmp$, i)
            dfs_int network$, visited$, neighbour$
         next
     end if
'
end sub


wlog "Following is the Depth-First Search"

r$=""
dfs network$, "E", r$
wlog "result:", r$

