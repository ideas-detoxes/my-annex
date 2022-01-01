import json
import os
import time
import sys
try:
	import uasyncio as asyncio
except:
	import asyncio

from nanoweb import HttpError, Nanoweb, send_file

try:
	from ubinascii import a2b_base64 as base64_decode
except:
	from binascii import a2b_base64 as base64_decode


sys.path.insert(0, './')

EXAMPLE_ASSETS_DIR = './www/'


def get_time():
    uptime_s = int(time.ticks_ms() / 1000)
    uptime_h = int(uptime_s / 3600)
    uptime_m = int(uptime_s / 60)
    uptime_m = uptime_m % 60
    uptime_s = uptime_s % 60
    return (
        '{}-{:02d}-{:02d} {:02d}:{:02d}:{:02d}'.format(*time.localtime()),
        '{:02d}h {:02d}:{:02d}'.format(uptime_h, uptime_m, uptime_s),
    )

async def api_send_response(request, code=200, message="OK"):
    await request.write("HTTP/1.1 %i %s\r\n" % (code, message))
    await request.write("Content-Type: application/json\r\n\r\n")
    await request.write('{"status": true}')

async def api_send_response_text(request, code=200, message="OK", text=''):
    await request.write("HTTP/1.1 %i %s\r\n" % (code, message))
    await request.write("Content-Type: text/plain\r\n\r\n")
    await request.write(text)
    print(f"Response: {text}")


async def api_status(request):
    """API status endpoint"""
    await request.write("HTTP/1.1 200 OK\r\n")
    await request.write("Content-Type: application/json\r\n\r\n")

    time_str, uptime_str = get_time()
    await request.write(json.dumps({
        "time": time_str,
        "uptime": uptime_str,
        'python': '{} {} {}'.format(
            sys.implementation.name,
            '.'.join(
                str(s) for s in sys.implementation.version
            ),
            sys.implementation.mpy
        ),
        'platform': str(sys.platform),
    }))



 

async def api_download(request):
    await request.write("HTTP/1.1 200 OK\r\n")

    filename = request.url[len(request.route.rstrip("*")) - 1:].strip("/")

    await request.write("Content-Type: application/octet-stream\r\n")
    flen=os.stat(filename)[6]
    await request.write(f"Content-Length: {flen}\r\n")
    await request.write("Content-Disposition: attachment; filename=%s\r\n\r\n" % filename)
    await send_file(request, filename)



async def api_delete(request):
    if request.method != "DELETE":
        raise HttpError(request, 501, "Not Implemented")

    filename = request.url[len(request.route.rstrip("*")) - 1:].strip("\/")

    try:
        os.remove(filename)
    except OSError as e:
        raise HttpError(request, 500, "Internal error")

    await api_send_response(request)



async def upload(request):
    if request.method != "PUT":
        raise HttpError(request, 501, "Not Implemented")

    bytesleft = int(request.headers.get('Content-Length', 0))

    if not bytesleft:
        await request.write("HTTP/1.1 204 No Content\r\n\r\n")
        return

    output_file = request.url[len(request.route.rstrip("*")) - 1:].strip("\/")
    tmp_file = output_file + '.tmp'

    try:
        with open(tmp_file, 'wb') as o:
            while bytesleft > 0:
                chunk = await request.read(min(bytesleft, 64))
                o.write(chunk)
                bytesleft -= len(chunk)
            o.flush()
    except OSError as e:
        raise HttpError(request, 500, "Internal error")

    try:
        os.remove(output_file)
    except OSError as e:
        pass

    try:
        os.rename(tmp_file, output_file)
    except OSError as e:
        raise HttpError(request, 500, "Internal error")

    await api_send_response(request, 201, "Created")



async def assets(request):
    await request.write("HTTP/1.1 200 OK\r\n")

    args = {}

    filename = request.url.split('/')[-1]
    if filename.endswith('.png'):
        args = {'binary': True}

    await request.write("\r\n")

    await send_file(
        request,
        './%s/%s' % (EXAMPLE_ASSETS_DIR, filename),
        **args,
    )



async def index(request):
    await request.write(b"HTTP/1.1 200 Ok\r\n\r\n")

    await send_file(
        request,
        './%s/index.html' % EXAMPLE_ASSETS_DIR,
    )

async def api_mkdir(request):
    if request.method != "GET":
        raise HttpError(request, 501, "Not Implemented")
    print(f"Request: {request.url}")
    filename = request.url[len(request.route.rstrip("*")) - 1:].strip("\/")
    try:
        os.system(f"./mkdir.sh {filename}")
    except OSError as e:
        raise HttpError(request, 500, "Internal error")
    print(f"Directory {filename} created.")
    await api_send_response_text(request, 201, "Created", 'Created')


def listdir(path='./'):
    ret=[]
    for f in os.ilistdir(path):
        fn=f[0]
        if fn == '.' or fn == '..':
            pass
        else:
            stat=os.stat(path+fn)
            if stat[3]==2:
                pass
            else:
                ret.append(path+fn)
    return ret
	

async def api_ls(request):
    print(f"Request: {request.url}")
    path = request.url[len(request.route.rstrip("*")) - 1:].strip("/")+"/"
    response = '%s' % ' '.join(f for f in sorted(listdir(path)))
    await api_send_response_text(request, 201, 'Listed', response)
#    print(f"Response:{response}")
#    await request.write(response)


naw = Nanoweb(8080)
naw.assets_extensions += ('ico',)
naw.STATIC_DIR = EXAMPLE_ASSETS_DIR

# Declare route from a dict
# naw.routes = {
#     '/': index,
#     '/assets/*': assets,
#     '/api/upload/*': upload,
#     '/api/status': api_status,
#     '/api/ls': api_ls,
#     '/api/download/*': api_download,
#     '/api/delete/*': api_delete,
# }

naw.routes = {
    '/api/mkdir/*': api_mkdir,
    '/api/ls/*': api_ls,
    '/api/download/*': api_download,
    '/index*': api_download,
    '/assets/*': assets,
    '/api/upload/*': upload,
    '/api/status': api_status,
    '/api/delete/*': api_delete,
}

# Declare route directly with decorator
@naw.route("/ping")
async def ping(request):
    await request.write("HTTP/1.1 200 OK\r\n\r\n")
    await request.write("pong")


loop = asyncio.get_event_loop()
loop.create_task(naw.run())
loop.run_forever()

