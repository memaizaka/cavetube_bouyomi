# coding : utf-8

require 'eventmachine'
require 'em-http-request'

class MySocketIO
  attr_accessor :on_open, :on_error, :receive_data, :receive_json, :disconnected
  
  def initialize(uri, port)
    @uri = uri
    @port = port
    @http
    @on_error = ->{$stderr.print "errorback"}
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
          
          @http.errback &@on_error
          
          @http.callback &@on_open
          
          @http.stream do |msg|
            case msg
              when /\A0:/
                send("0")
              when /\A1:/
              when /\A2::/
                send("2::")
              when /\A3:::(.+)/
                @receive_data.call($1)
              when /\A4:[^:]*:[^:]*:(.+)/
                @receive_json.call($1)
              else
                puts "else"
            end
          end
          
          @http.disconnect &@disconnected
        end
      end
    end
  end
end
