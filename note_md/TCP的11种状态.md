代码 | 详细信息
-----|---
CLOSED |	初始状态，表示TCP连接是“关闭着的”或“未打开的				
LISTEN |	监听状态,可接受客户端请求				
SYN_RCVD |	表示服务器接收到了请求连接的SYN报文	
SYN_SENT |  当客户端SOCKET执行connect()进行连接时，它首先发送SYN报文，然后随即进入到SYN_SENT 状态,表示已经发送了SYN报文"				
ESTABLISHED |	连接已经建立				
FIN_WAIT_1 |	等待对方的FIN报文				
FIN_WAIT_2 |	FIN_WAIT_2状态下的SOCKET处于半连接,因为有一方要求关闭连接,如有一方不配合完成四次挥手,FIN_WAIT_2会一直保存到重启		
TIME_WAIT |	收到了对方的FIN报文，并发送出了ACK报文				
CLOSING |	没有收到对方的ACK报文，收到了对方的FIN报文				
CLOSE_WAIT |	表示正在等待关闭				
LAST_ACK |	被动关闭的一方在发送FIN报文后，等待对方的ACK报文的应答2			