#!/usr/bin/python
import sys
import asyncio
import websockets
import time
import urllib.request
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)


esps={}
allIsRunning = False
verifyError = False
programtext=''
programfilename=''

async def check(ip):
    global esps
    uri = f"ws://{ip}/ws"
    try:
        async with websockets.connect(uri, open_timeout=0.5, subprotocols=["Editor"] ) as websocket:
            esps[ip]=True
    except:
        pass

async def killer():
    while True:
        await asyncio.sleep(0.01)
        t=asyncio.all_tasks()
        if len(t) == 1:
            return

def scan(network):
    t1 = time.time_ns()
    (i1, i2, i3, i4) = network.split(".")
    net = ".".join( (i1, i2, i3) )
    loop = asyncio.get_event_loop()
    print("Scanning...")
    for i in range(1,254):
        loop.create_task(check(f"{net}.{i}"))
    loop.run_until_complete(killer())
    t2 = time.time_ns()
    print(f"done in {int((t2-t1)/1000000)} ms")
    for e in esps:
        print(f"Live: {e}")

async def uploadFile(ip):
    global verifyError
    uri = f"ws://{ip}/ws"
    pos=0
    size=512
    print(f"Uploading {programfilename} to {ip} ")
    async with websockets.connect(uri, open_timeout=0.5, subprotocols=["Editor"] ) as websocket:
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


def uploadFileToAll():
    global verifyError
    verifyError = False
    loop = asyncio.get_event_loop()
    for e in esps:
        loop.create_task(uploadFile(e))
    loop.run_until_complete(killer())

async def loadAndRunWithLog(ip):
    global allIsRunning
    uri = f"ws://{ip}/ws"
    print(f"Starting {programfilename} on {ip}.")
    async with websockets.connect(uri, open_timeout=0.5, subprotocols=["Editor"] ) as websocket:
        await websocket.send(f"cmd:stop")
        await websocket.send(f"load/{programfilename}")
        await websocket.send(f"cmd:run")
        resp = await websocket.recv()
        while allIsRunning:
            resp = await websocket.recv()
            await websocket.send("$")
            print(f"[{ip}] -- {resp}")
        await websocket.send(f"cmd:stop")        
        resp = await websocket.recv()
        await websocket.send(f"cmd:stop")        
        resp = await websocket.recv()
        await websocket.send(f"cmd:stop")        
        resp = await websocket.recv()
            
def loadAndRunWithLogAll():
    global allIsRunning
    allIsRunning = True
    loop = asyncio.get_event_loop()
    for e in esps:
        loop.create_task(loadAndRunWithLog(e))
    try:
        loop.run_until_complete(killer())
    except KeyboardInterrupt:
        allIsRunning = False
        for task in asyncio.Task.all_tasks():
            task.cancel()


async def sendStop(ip):
    uri = f"ws://{ip}/ws"
    print(f"Stopping program on {ip}.")
    async with websockets.connect(uri, open_timeout=0.5, subprotocols=["Editor"] ) as websocket:
        await websocket.send(f"cmd:stop")
    
def stopAll():
    loop = asyncio.get_event_loop()
    for e in esps:
        loop.create_task(sendStop(e))
    loop.run_until_complete(killer())
        
             
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
                stopAll()
            print("Stopped.")
        except FileNotFoundError:
            print(f"Cannot read file: {programfilename}")
    else:
        print(f"Usage: {sys.argv[0]} filename.bas")

