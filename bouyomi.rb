# coding:utf-8

# gae.cavelis.netのコメントを棒読みちゃんのSocket通信に送りつけます
# 使い方： ruby bouyomi.rb 配信URLの最後の文字列(例：5E0AFA3101F44CBDB5DC0291848EB4A2)
#
require 'net/http'
# require 'time' # 時間まで取得したいときは必要
require 'em-http-request'
require 'json'
require './bouyomi_socket'

if ARGV.size == 1
  room_no = ARGV.shift
else
  print "Please Enter RoomID >> "
  room_no = gets.chomp
end 

Net::HTTP.version_1_2
session_id = ''
Net::HTTP.start("ws.cavelis.net", 3000) do |http|
  session_id = http.get("/socket.io/1/websocket/").body.split(/:/)[0]
end
puts "get session_id => #{session_id}"

b = BouyomiSocket.new

EventMachine.run do
  http = EventMachine::HttpRequest.new("ws://ws.cavelis.net:3000/socket.io/1/websocket/#{session_id}").get :timeout => 0

  http.errback { puts "Error" }
  http.callback {
    puts "WebSocket Connected!"
    enter_room = {'mode'=>'join','room'=>room_no}.to_json
    http.send("3:::" + enter_room)
  }

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
          b.talk("#{res['comment_num']}番")
          b.talk("#{res['name']} さん") if res['name'].size > 0
          b.talk(res['message'])
          # puts "#{res['comment_num']}: #{res['name']} : [#{Time.at(res['time']/1000).localtime}]", res['message']
        elsif res['mode'] == 'join' || res['mode'] == 'leave'
          # puts "#{res['mode']} RoomID => #{res['room']} id => #{res['id']}"
          puts "listener count => #{res['ipcount']}"
        else res['mode'] == 'close_entry'
          puts "close"
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

puts "closing script"

=begin
post message
ret false
stream_name
_session
name
message

ret true
mode post
name
message
=end