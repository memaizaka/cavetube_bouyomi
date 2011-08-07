#coding:utf-8
require 'uri'
require 'net/http'
require 'socket'
require 'digest/md5'

class WebSocketClient
  def initialize
    @uri = URI('ws://ws.cavelis.net:3000')
    @session_id
    @socket
    @key1
    @num1
    @key2
    @num2
    @key_body
  end
  
  def generate_sec_key
    r = Random.new
    spaces = r.rand(1..13)
    m = (2 ** 32 - 1) / spaces
    num = r.rand(2 ** 32 - 1) % m
    # puts num
    product = num * spaces
    
    key = product.to_s
    r.rand(1..13).times do
      position = r.rand(2 ** 32 - 1) % key.size
      if rand(2) == 0
        char = r.rand(0x21..0x2f).chr #before numbers
      else
        char = r.rand(0x3A..0x7E).chr #after numbers
      end
      key.insert(position, char)
    end
    
    spaces.times do
      key.insert(r.rand(2 ** 32 - 1) % key.size + 1, ' ')
    end
    
    return key, num
  end
  
  def generate_body_key
    r = Random.new
    key = ''
    8.times do
      key << r.rand(0x021..0x07e).chr
    end
    key
  end
  
  def check_key(rec_key)
    sendkey = ''
    space1 = @key1.count(' ')
    space2 = @key2.count(' ')
    num1   = @key1.gsub(/\D/, '').to_i
    num2   = @key2.gsub(/\D/, '').to_i
    k1 = num1 / space1
    k2 = num2 / space2
    puts "key1 => %s : num1 => %s" % [k1, @num1]
    puts "key2 => %s : num2 => %s" % [k2, @num2]
    puts "keyb => %s" % @key_body
    puts "rec_key => #{rec_key}, size = #{rec_key.bytesize}"
    kk1 = [k1].pack("N")
    kk2 = [k2].pack("N")
    sendkey << kk1 << kk2 << @key_body
    puts "hexadecimal : %s %s %s" % [*kk1.unpack("h*"), *kk2.unpack("h*"), *@key_body.unpack("h*")]
    puts "sendkey in hex : %s" % sendkey.unpack("h*")
    puts "sendkey size: #{sendkey.size}"
    puts "byte send key => %s" % sendkey
    skey  = Digest::MD5.digest(sendkey)
    puts "sendkey after digest => #{skey}"
    skeyh = Digest::MD5.hexdigest(sendkey)
    puts "skey in hexadecimal : %s" % skeyh
    puts "rec_key in hexadecimal : %s" % rec_key[0..15].unpack("H*")
    rest = rec_key[16..-1]
    puts rest.unpack("H*") # what is this ?!
    # 0x00 0x31 0x3a 0x3a 0xff 0x00 0x32 0x3a 0x3a 0xff
    # 0x00 [data] 0xff がwebsocketのチャンク
    #　"1::" "2::"
    #　connect heartbeatがすぐにきてました。
    # keep-aliveだからline == nilを停止条件にしてたらhandshake responseの次も取ってたらしい
    
    if skey == rec_key[0..15]
      "YES"
    else
      "NO"
    end
  end
  
  def open &block
    begin
      @socket = TCPSocket.new(@uri.host, @uri.port)
    rescue SocketError=> e
      p e
      return nil
    end
    Net::HTTP.version_1_2
    
    begin
      Net::HTTP.start('ws.cavelis.net', 3000) {|http|
        response = http.get('/socket.io/1/')
        @session_id = response.body.split(/:/)[0]
      }
    end
    @key1, @num1 = generate_sec_key
    @key2, @num2 = generate_sec_key
    @key_body   = generate_body_key
    reqh = "GET /socket.io/1/websocket/#{@session_id} HTTP/1.1\r\n"
    reqh << "Upgrade: WebSocket\r\n"
    reqh << "Connection: Upgrade\r\n"
    reqh << "Host: ws.cavelis.net\r\n"
    reqh << "Origin: http://ws.cavelis.net:3000\r\n"
    reqh << "Sec-WebSocket-Protocol: socket.io\r\n"
    reqh << "Sec-WebSocket-Key1: #{@key1}\r\n"
    reqh << "Sec-WebSocket-Key2: #{@key2}\r\n"
    reqh << "\r\n"
    reqh << @key_body
    @socket.print reqh
    
    puts '-' * 25 + " request  " + '-' * 25    
    print reqh
    puts
    puts '-' * 25 + " response " + '-' * 25

    if block_given?
      yield @socket
    end
    @socket
  end
end

buf = ''
wsc = WebSocketClient.new
soc = wsc.open do |s|
  until (line = s.recv(1024)) == ''
    buf << line
  end
  puts buf
  puts '-' * 25 + " check result " + '-' * 25
  buf =~ /[\n][\r]?[\n]/
  rec_key = $'.chomp
  puts "authanticated? => #{wsc.check_key(rec_key)}"
end
if soc
  soc.puts("0")
  soc.close
end

