'''
Author:notme
only command shell is useful
'''
import sys
import socket
import getopt
import threading
import subprocess

listen = False
command = False
upload = False
execute = b'\n'
host = ''
port = 0
upload_dest = ''

def usage():
    print('pynet.py -t target_ip -p target_port')
    print('-l --listen')
    # print('-e --execute=orders')
    print('-c --command')
    # print('-u --upload=destination')
    print('Examples:')
    print('pynet.py -t 127.0.0.1 -p 6661 -l -c')
    print('pynet.py -t 127.0.0.1 -p 6661')
    # print('pynet.py -t 127.0.0.1 -p 6661 -l -u /etc/passwd')
    # print('pynet.py -t 127.0.0.1 -p 6661 -l -e whoami')
    # print('echo "ABCD" | ./pynet.py -t 127.0.0.1 -p 135')
    sys.exit(0)

def main():
    global listen
    global host
    global port
    global execute
    global command
    # global upload
    global upload_dest

    if not len(sys.argv[1:]):
        usage()

    try:
        opts,args = getopt.getopt(sys.argv[1:],"hle:t:p:cu:",["help", "listen", "execute", "target", "port", "command", "upload"])
    except getopt.GetoptError as error:
        print(str(error))
        usage()
    for o,a in opts:
        if o in ("-h","--help"):
            usage()
        elif o in ("-l","--listen"):
            listen = True
        elif o in ("-c","--command"):
            command = True
        elif o in ("-e", "--execute"):
            execute = bytes(a,encoding='utf-8')+b'\n'
            print(execute)
        elif o in ("-u", "--upload"):
            upload_dest = a
            # print(upload_dest)
        elif o in ("-t", "--target"):
            host = a
        elif o in ("-p","--port"):
            port = int(a)
        else:
            assert False,"Unhandled Option"

    if not listen and len(host) and port != 0:
        # buffer = sys.stdin.read()
        buffer = b''
        client_sender(buffer)
    if listen:
        server_loop()

def client_sender(buffer):
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        client.connect((host,port))
        # if len(buffer):
        #     # client.send(bytes(buffer,encoding = "utf8"))
        #     client.send(buffer)

        while True:
            read_command_res(client)
            # client_printer = threading.Thread(target=read_command_res,args=(client,))
            # client_printer.start()
            buffer_str = input("")
            buffer = bytes(buffer_str,encoding='utf-8')
            buffer += b'\n'

            client.send(buffer)
            # client.send(bytes(buffer,encoding = "utf8"))
    except:
        print('[ERR] Exception! Exiting.')
        client.close()

def read_command_res(client):
    recv_len = 1
    response = b""
    # print('开始读数据')
    while recv_len:
        data = client.recv(2048)
        recv_len = len(data)
        response += data
        if recv_len < 2048:
            break
    print(str(response,encoding='utf-8'),end='')

def server_loop():
    global host
    if not len(host):
        host = "0.0.0.0"
    server = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    server.bind((host,port))
    server.listen(5)
    print("[*] Listening on %s:%d" % (host,port))
    while True:
        client_socket,addr =server.accept()
        print("[*] Accepted connection from: %s:%d" % (addr[0],addr[1]))
        try:
            client_thread = threading.Thread(target=client_handler,args=(client_socket,))
            client_thread.start()
        except:
            print('[ERR] thread fail')
        # print('connet establish!')

def run_command(command):
    # print("run_command")
    command = command.rstrip()
    try:
        output = subprocess.check_output(command,stderr=subprocess.STDOUT,shell=True)
    except:
        output = 'Failed to execute command.\r\n'
    return output

def client_handler(client_socket):
    global upload
    global execute
    global command
    if len(upload_dest):
        file_buffer = ''
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            else:
                file_buffer += data
        try:
            file_descriptor = open(upload_dest,'wb')
            file_descriptor.write(file_buffer)
            file_descriptor.close()

            client_socket.send('Succuessfully saved file to %s\r\n' % upload_dest)
        except:
            client_socket.send('[ERR]Failed to saved file to %s\r\n' % upload_dest)
    '暂时不可用'
    if len(execute):
        # print(execute)
        output = run_command(execute)
        # print(output)
        # client_socket.send(bytes(output, encoding = "utf8"))
        client_socket.send(output)

    if command:
        while True:
            client_socket.send(b"<shell:#> ")
            cmd_buffer = b''
            while b'\n' not in cmd_buffer:
                cmd_buffer += client_socket.recv(1024)
            # print(cmd_buffer)
            response = run_command(cmd_buffer)
            client_socket.send(response)

if __name__ == '__main__':
    main()