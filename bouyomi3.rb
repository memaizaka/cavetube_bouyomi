#coding:utf-8

require_relative 'socket_io'
require_relative 'bouyomi_em_socket'

require 'json'

room_no = '85FC5A5DD06D4863B7C385DAFDE4F646'
b = BouyomiSocket.new
wb = MySocketIO.new('ws.cavelis.net', 3000)

wb.on_open = Proc.new do
  puts "WebSocket Connected!"
  $stderr.print "WebSocket Connected!"
  enter_room = {'mode'=>'join','room'=>room_no}.to_json
  wb.send("3:::" + enter_room)
end

wb.receive_data = Proc.new do |data|
  res = JSON.parse(data)
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
end

wb.disconnected = Proc.new do
  puts "Disconnected"
end

wb.run