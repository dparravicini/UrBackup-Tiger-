import socket,struct,json,urllib.parse
class API:
 def __init__(self):self.session=''
 def request(self,action,**params):
  if self.session:params['ses']=self.session
  body=urllib.parse.urlencode(params).encode();s=socket.create_connection(('127.0.0.1',55413),5);s.settimeout(30)
  def rec(t,b=b''):return struct.pack('!BBHHBB',1,t,1,len(b),0,0)+b
  def plen(n):return bytes([n]) if n<128 else struct.pack('!I',n|0x80000000)
  env={'REQUEST_METHOD':'POST','QUERY_STRING':'a='+action,'SCRIPT_NAME':'/x','REQUEST_URI':'/x?a='+action,'SERVER_PROTOCOL':'HTTP/1.1','REMOTE_ADDR':'127.0.0.1','SERVER_NAME':'localhost','CONTENT_TYPE':'application/x-www-form-urlencoded','CONTENT_LENGTH':str(len(body))}
  b=b''
  for k,v in env.items():k=k.encode();v=v.encode();b+=plen(len(k))+plen(len(v))+k+v
  s.sendall(rec(1,b'\x00\x01'+b'\x00'*6)+rec(4,b)+rec(4)+rec(5,body)+rec(5))
  def read(n):
   b=b''
   while len(b)<n:
    t=s.recv(n-len(b))
    if not t:raise EOFError()
    b+=t
   return b
  out=b''
  try:
   while True:
    ver,t,rid,n,pad,_=struct.unpack('!BBHHBB',read(8));b=read(n);read(pad)
    if t==6:out+=b
    if t==3:break
  finally:s.close()
  r=json.loads(out.split(b'\r\n\r\n',1)[-1])
  if r.get('session'):self.session=r['session']
  return r
if __name__=='__main__':
 api=API();r=api.request('login');print('Login success:',r.get('success'),'error:',r.get('error'),'session received:',bool(api.session))
 if r.get('success'):
  r=api.request('status');print('Status keys:',','.join(r.keys()),'error:',r.get('error'),'client count:',len(r.get('status',[])))
