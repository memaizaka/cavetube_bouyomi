# coding:utf-8

require 'eventmachine'

class Bouyomi < EM::Connection
  attr_reader :res
  def receive_data(data)
    @res << data
    close_connection_after_writing
  end
end

class BouyomiSocket
  attr_accessor :speed, :tone, :volume, :voice
  def initialize
    @speed  = -1 # 速度(-1：デフォルト, 50～300)
    @tone   = -1 # 音程(-1：デフォルト, 50～200)
    @volume = -1 # 音量(-1：デフォルト,  0～100)
    @voice  =  0 # 声質( 0：デフォルト,  1～8:AquesTalk, 10001～:SAPI5)
    @code   =  0 # 文字列の文字コード(0:UTF-8, 1:Unicode, 2:Shift-JIS)
    @wb
  end

  # if you want tcp response, add block
  def send_data(*data, &block)
    @wb = EM.connect("localhost", 50001, Bouyomi)
    #怪しい
    [*data].each do |d|
      @wb.send_data(d)
    end
    if block_given?
      response = @wb.res
      ret = yield response
      return ret
    end
  end
  
  def talk(msg)
    data = [0x0001, @speed, @tone, @volume, @voice, @code, msg.bytesize].pack("v5cl")
    send_data(data, msg)
  end
  
  def pause
    data = [0x0010].pack "v"
    send_data(data)
  end
  
  def resume
    data = [0x0020].pack "v"
    send_data(data)
  end
  
  def paused?
    data = [0x0110].pack "v"
    response = send_data(data){|ret| ret.unpack("c")}
    return 1 == response[0]
  end
  
  def playing?
    data = [0x0120].pack "v"
    response = send_data(data){|ret| ret.unpack("c")}
    return 1 == response[0]
  end

  def get_task_count
    data = [0x0130].pack "v"
    response = send_data(data){|ret| ret.unpack("l")}
    return response[0]
  end
  
  def clear_task
    data = [0x0040].pack "v"
    send_data(data)
  end
  
  def skip
    data = [0x0030].pack "v"
    send_data(data)
  end
end
