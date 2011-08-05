#coding:utf-8

require_relative 'socket_io'
require_relative 'bouyomi_em_socket'

require 'json'
unless Encoding.find("locale") == Encoding::ASCII_8BIT
  $stderr.puts Encoding.find("locale")
end 

room_no = ARGV.shift || '/'
b = BouyomiSocket.new
wb = MySocketIO.new('ws.cavelis.net', 3000)

wb.on_open = Proc.new do
  puts "WebSocket Connected!"
  $stderr.puts "WebSocket Connected!"
  enter_room = {'mode'=>'join','room'=>room_no}.to_json
  wb.send("3:::" + enter_room)
end

wb.receive_data = Proc.new do |data|
  res = JSON.parse(data)
  if room_no == '/'
    p res
    #　こっちはめんどくさいんで最初からエンコード
    unless Encoding.find("locale") == Encoding::ASCII_8BIT
      res['name'] = res['name'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
      res['title'] = res['title'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
    end
    case res['mode']
    when 'start_entry'
      puts '新しい配信が始まりました。'
      puts "#{res['name']}さん : #{res['title']}"
    when 'close_entry'
      puts '配信が終了しました'
      puts "#{res['name']}さん : #{res['title']}"
    end
  else
    if res['mode'] == 'post'
      Fiber.new do
        b.talk "#{res['comment_num']}番"
        b.talk res['name'] + "さん" if res['name'].size > 0
        b.talk res['message']
      end.resume
      begin
        $stderr.puts "#{res['comment_num']}: #{res['name']} : [#{Time.at(res['time']/1000).localtime}]", res['message']
      rescue =>e
        # 最初からencodeしちゃってもいいけどここに来るかテスト
        $stderr.puts "文字に変換できないコードが含まれています : #{e.inspect}"
        $stderr.puts "#{res['comment_num']}: #{res['name']} : [#{Time.at(res['time']/1000).localtime}]", res['message'].encode(Encoding.locale_charmap, :invalid=>:replace, :undef => :replace)
      end
    elsif res['mode'] == 'join' || res['mode'] == 'leave'
      # puts "#{res['mode']} RoomID => #{res['room']} id => #{res['id']}"
      puts "listener count => #{res['ipcount']}"
    else res['mode'] == 'close_entry' && res['stream_name'] == room_no
      $stderr.puts "close entry sign"
      b.talk("配信が終了しました")
      EM::add_timer(1){EM::stop}
    end
  end
end

wb.disconnected = Proc.new do
  puts "Disconnected"
end

wb.run