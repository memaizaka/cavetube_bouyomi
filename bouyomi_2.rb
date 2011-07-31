#coding:utf-8

require 'eventmachine'
require 'em-http-request'
require 'json'
require_relative 'bouyomi_em_socket'

room_no = ARGV.shift

EM.run do
  conn = EM::Protocols::HttpClient2.connect 'ws.cavelis.net', 3000
  req = conn.get('/socket.io/1/')
  req.callback do |res|
    sid = res.content.split(/:/).first
    EM.next_tick do
      b = BouyomiSocket.new
      http = EventMachine::HttpRequest.new("ws://ws.cavelis.net:3000/socket.io/1/websocket/#{sid}").get :timeout => 0

      http.errback do
        puts "Error"
      end
      
      http.callback do
        puts "WebSocket Connected!"
        enter_room = {'mode'=>'join','room'=>room_no}.to_json
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
            res = JSON.parse($1)
            if res['mode'] == 'post'
              t = Fiber.new do
                b.talk "#{res['comment_num']}番"
                b.talk res['name'] + "さん" if res['name'].size > 0
                b.talk res['message']
              end
              t.resume
              puts "#{res['comment_num']}: #{res['name']} : [#{Time.at(res['time']/1000).localtime}]", res['message']
            elsif res['mode'] == 'join' || res['mode'] == 'leave'
              # puts "#{res['mode']} RoomID => #{res['room']} id => #{res['id']}"
              puts "listener count => #{res['ipcount']}"
            else res['mode'] == 'close_entry' && res['stream_name'] == room_no
              puts "close entry sign"
              b.talk("配信が終了しました")
              EM::stop
            end
          when /\A4:[^:]*:[^:]*:(.+)/
            res = JSON.parse($1)
          else
            puts "else"
        end
      end

      http.disconnect do
        puts "Disconnected!"
      end
    end
  end
end