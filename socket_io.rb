# coding : utf-8

require 'eventmachine'
require 'em-http-request'

class MySocketIO
  attr_reader :room_no
  
  def initialize(room_no)
    @room_no = room_no
    @callback_action = nil
    @errback_action = nil
    @receive_data_action = nil
    @receive_json_action = nil
    @disconnected_action = nil
  end
  
  # set action
  def receive_data=(da)
    @receive_data_action = da
  end
  
  def receive_json=(ja)
    @receive_json_action = ja
  end
  
  def disconnected=(dis)
    @disconnected_action = dis
  end
  
  def run
    EM.run do
      conn = EM::Protocols::HttpClient2.connect 'ws.cavelis.net', 3000
      req = conn.get('/socket.io/1/')
      req.callback do |res|
        sid = res.content.split(/:/).first
        EM.next_tick do
          http = EventMachine::HttpRequest.new("ws://ws.cavelis.net:3000/socket.io/1/websocket/#{sid}").get :timeout => 0
          
          http.errback do
            $stderr.print "errorback"
          end
          
          http.callback do
            puts "WebSocket Connected!"
            $stderr.print "WebSocket Connected!"
            enter_room = {'mode'=>'join','room'=>@room_no}.to_json
            http.send("3:::" + enter_room)
          end
          
          http.stream do |msg|
            case msg
              when /\A0:/
                http.send("0")
              when /\A1:/
              when /\A2::/
                http.send("2::")
              when /\A3:::(.+)/
                @receive_data_action.call($1)
              when /\A4:[^:]*:[^:]*:(.+)/
                @receive_json_action.call($1)
              else
                puts "else"
            end
          end
          
          http.disconnect do
            @disconnected_action.call
          end
        end
      end
    end
  end
end
