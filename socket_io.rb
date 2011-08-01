# coding : utf-8

require 'eventmachine'
require 'em-http-request'

class MySocketIO
  attr_reader :room_no
  
  def initialize(uri, port)
    @uri = uri
    @port = port
    @on_open = nil
    @http
    @receive_data_action = nil
    @receive_json_action = nil
    @disconnected_action = nil
  end
  
  # set action
  def on_open=(op)
    @on_open = op
  end
  
  def receive_data=(da)
    @receive_data_action = da
  end
  
  def receive_json=(ja)
    @receive_json_action = ja
  end
  
  def disconnected=(dis)
    @disconnected_action = dis
  end
  
  def send(data)
    @http.send(data)
  end
  
  def run
    EM.run do
      conn = EM::Protocols::HttpClient2.connect @uri, @port
      req = conn.get('/socket.io/1/')
      req.callback do |res|
        sid = res.content.split(/:/).first
        EM.next_tick do
          @http = EventMachine::HttpRequest.new("ws://#{@uri}:#{@port}/socket.io/1/websocket/#{sid}").get :timeout => 0
          
          @http.errback do
            $stderr.print "errorback"
          end
          
          @http.callback do
            @on_open.call
          end
          
          @http.stream do |msg|
            case msg
              when /\A0:/
                send("0")
              when /\A1:/
              when /\A2::/
                send("2::")
              when /\A3:::(.+)/
                @receive_data_action.call($1)
              when /\A4:[^:]*:[^:]*:(.+)/
                @receive_json_action.call($1)
              else
                puts "else"
            end
          end
          
          @http.disconnect do
            @disconnected_action.call
          end
        end
      end
    end
  end
end
