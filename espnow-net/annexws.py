#!/usr/bin/python
import sys
import asyncio
import websockets
import time
import urllib.request
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)
import select

import sys
import select
import tty
import termios

console_old_settings=None
class NonBlockingConsole(object):

    def __enter__(self):
        global console_old_settings
        console_old_settings = termios.tcgetattr(sys.stdin)
        tty.setcbreak(sys.stdin.fileno())
        return self

    def __exit__(self, type, value, traceback):
        global console_old_settings
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, console_old_settings)


    def get_data(self):
        if select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], []):
            return sys.stdin.read(1)
        return False
        


esps={}
allIsRunning = False
verifyError = False
programtext=''
programfilename='b.bas'
taskcnt=0
loop = None

async def check(ip):
    global taskcnt
    global esps
    uri = f"ws://{ip}/ws"
    try:
        async with websockets.connect(uri, open_timeout=0.5, subprotocols=["Editor"] ) as websocket:
            esps[ip]=True
    except:
        pass
    taskcnt -= 1

async def killer(taskcount):
    while True:
        await asyncio.sleep(0.01)
        t=asyncio.all_tasks()
        if len(t) <= taskcount:
            return

async def newkiller(taskcount):
    global taskcnt
    while taskcnt > taskcount:
        await asyncio.sleep(0.01)

def scan(network):
    global taskcnt
    global loop
    tmp = taskcnt
    t1 = time.time_ns()
    (i1, i2, i3, i4) = network.split(".")
    net = ".".join( (i1, i2, i3) )
    loop = asyncio.get_event_loop()
    print("Scanning...")
    for i in range(1,254):
        taskcnt += 1
        loop.create_task(check(f"{net}.{i}"))
    loop.run_until_complete(newkiller(tmp))
    t2 = time.time_ns()
    print(f"done in {int((t2-t1)/1000000)} ms")
    for e in esps:
        print(f"Live: {e}")

async def uploadFile(ip):
    global verifyError
    global taskcnt
    uri = f"ws://{ip}/ws"
    pos=0
    size=512
    print(f"Uploading {programfilename} to {ip} ")
    async with websockets.connect(uri, open_timeout=3, subprotocols=["Editor"] ) as websocket:
        await websocket.send(f"save:start/{programfilename}")
        while True:
            resp = await websocket.recv()
            #print(resp)
            await websocket.send("$")
            if resp.startswith("SAVE:GIVE"):
                snd=f"save:more{programtext[pos:(pos+size)]}"
                #print(f"{snd}")
                await websocket.send(snd)
                pos += size
            elif resp.startswith("SAVE:END"):
                break
            else:
                print("ERROR")
                return
        await websocket.send(f"load:/{programfilename}")
        await websocket.send("$")
#        await websocket.send("cmd:immediate wlog time$")
#        resp = await websocket.recv()
#        print(f"{ip} >>> {resp}")
    with urllib.request.urlopen(f"http://{ip}/{programfilename}") as f:
        txt = f.read().decode('utf-8')
    if txt == programtext:
        print(f"Upload {programfilename} to {ip} is OK.")
    else:
        print(f"Upload {programfilename} to {ip} is FAILED!")
        verifyError = True
    taskcnt -= 1


def uploadFileToAll():
    global verifyError
    global taskcnt
    global loop
    tmp = taskcnt
    verifyError = False
    loop = asyncio.get_event_loop()
    for e in esps:
        taskcnt+=1
        loop.create_task(uploadFile(e))
    loop.run_until_complete(newkiller(tmp))


async def printLog(ip):
    global allIsRunning
    uri = f"ws://{ip}/ws"
    async with websockets.connect(uri, open_timeout=3, subprotocols=["Editor"] ) as websocket:
        resp = await websocket.recv()
        while allIsRunning:
            resp = await websocket.recv()
            await websocket.send("$")
            resp = resp.replace("LOG:", "")
            resp = resp.replace("\n", f"\n[{ip}] ")
            print(f"[{ip}] {resp}")

async def loadAndRunWithLog(ip):
    global allIsRunning
    global taskcnt
    taskcnt = 0
    uri = f"ws://{ip}/ws"
    print(f"Starting {programfilename} on {ip}.")
    await sendCmd(ip, f"load/{programfilename}")
    await sendCmd(ip, "cmd:run")
    await printLog(ip)
    taskcnt -= 1
            
def loadAndRunWithLogAll():
    global allIsRunning
    global taskcnt
    global loop
    allIsRunning = True
    tmp = taskcnt
    loop = asyncio.get_event_loop()
    for e in esps:
        taskcnt += 1
        loop.create_task(loadAndRunWithLog(e))
    loop.create_task(kbd())
    loop.run_forever()


async def sendCmd(ip, cmd, log=False):
    uri = f"ws://{ip}/ws"
    if log:
        print(f"Sending {cmd} to {ip}.")
    async with websockets.connect(uri, open_timeout=3, subprotocols=["Editor"] ) as websocket:
        await websocket.send(cmd)
    
def sendCmdAll(cmd, log=False):
    global taskcnt
    global loop
    tmp = taskcnt
    loop = asyncio.get_event_loop()
    for e in esps:
        taskcnt += 1
        if loop.is_running():
            loop.create_task(sendCmd(e, cmd, log))
            pass
        else:
            loop.create_task(sendCmd(e, cmd, log))
        if loop.is_running():
            pass
        else:
            loop.run_until_complete(newkiller(tmp))


async def kbd():
    global allIsRunning
    global console_old_settings
    global loop
    with NonBlockingConsole() as nbc:
        while True:
            await asyncio.sleep(0.1)
            ch = nbc.get_data()
            if ch == '?':
                print("? - Help\np - Pause\nq - Quit\nr - Run(cont from pause)")
            elif ch == 'q':
                sendCmdAll("cmd:stop", True)
                await asyncio.sleep(1)
                termios.tcsetattr(sys.stdin, termios.TCSADRAIN, console_old_settings)
                allIsRunning = False
                loop.stop()
                for task in asyncio.Task.all_tasks():
                    try:
                        task.cancel()
                    except:
                        pass
                return
            elif ch == 'p':
                sendCmdAll("cmd:pause", True)
                await asyncio.sleep(0.5)
                termios.tcsetattr(sys.stdin, termios.TCSADRAIN, console_old_settings)
                cmd=input("Enter command: ")
                console_old_settings = termios.tcgetattr(sys.stdin)
                sendCmdAll(f"cmd:immediate {cmd}", True)
            elif ch == 'r':
                sendCmdAll("cmd:run", True)
                
if __name__ == "__main__":
    if len(sys.argv) == 2:
        programfilename = sys.argv[1]
        try:
            f = open(programfilename, "r")
            programtext = f.read()
            if not programtext.endswith("\n"):
                programtext += "\n"
            scan("10.42.0.0")
            uploadFileToAll()
            if verifyError == False:
                loadAndRunWithLogAll()
            print("Stopped.")
        except FileNotFoundError:
            print(f"Cannot read file: {programfilename}")
    else:
        print(f"Usage: {sys.argv[0]} filename.bas")

