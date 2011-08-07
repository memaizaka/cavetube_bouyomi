#coding:utf-8
# 必要なgem
# eventmachine 1.0.0.beta.3 x86-mingw32
# em-http-request 0.3.0
require_relative 'socket_io'
require_relative 'bouyomi_em_socket'

require 'json'

#unless Encoding.find("locale") == Encoding::ASCII_8BIT
#  $stderr.puts Encoding.find("locale")
#end 

room_no = ARGV.shift || '/'
EventMachine::run do
  b = BouyomiSocket.new
  wb = MySocketIO.new('ws.cavelis.net', 3000)
  
  wb.on_open = Proc.new do
    puts "WebSocket Connected!"
    # $stderr.puts "WebSocket Connected!"
    enter_room = {'mode'=>'join','room'=>room_no}.to_json
    wb.send("3:::" + enter_room)
    puts "enter : #{room_no}"
  end
  
  wb.receive_data = Proc.new do |data|
    res = JSON.parse(data)
    if room_no == '/'
      case res['mode']
      when 'leave', 'join'
        puts "listener count => #{res['ipcount']}"
      when 'start_entry'
        unless Encoding.find("locale") == Encoding::ASCII_8BIT
          author = res['author'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
          title = res['title'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
        end
        puts '新しい配信が始まりました。'
        puts "#{author}さん : #{title}"
      when 'close_entry'
        unless Encoding.find("locale") == Encoding::ASCII_8BIT
          author = res['author'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
          title = res['title'].encode(Encoding.locale_charmap, :invalid => :replace, :undef => :replace)
        end
        puts '配信が終了しました'
        puts "#{author}さん : #{title}"
      end
    else
      if res['mode'] == 'post'
        # 順番に送りたい
        #　現状たまに順番が狂う
        # まとめて送ってみる
        Fiber.new do
          comment =  "#{res['comment_num']}番\n"
          comment << res['name'] + "さん\n" if res['name'].size > 0
          comment << res['message']
          b.talk comment
        end.resume
        if Encoding.locale_charmap != Encoding::UTF_8 && Encoding.locale_charmap != "CP0"
          $stderr.puts "#{res['comment_num']}: #{res['name'].encode(Encoding.locale_charmap, :invalid=>:replace, :undef => :replace)} : [#{Time.at(res['time']/1000).localtime}]"
          $stderr.puts res['message'].encode(Encoding.locale_charmap, :invalid=>:replace, :undef => :replace)
        else
          $stderr.puts "#{res['comment_num']}: #{res['name']} : [#{Time.at(res['time']/1000).localtime}]"
          $stderr.puts res['message']
        end
      elsif res['mode'] == 'join' || res['mode'] == 'leave'
        # puts "#{res['mode']} RoomID => #{res['room']} id => #{res['id']}"
        puts "listener count => #{res['ipcount']}"
      elsif (res['mode'] == 'close_entry') && (res['stream_name'] == room_no)
        $stderr.puts "close broadcast"
        b.talk("配信が終了しました")
        EM::add_timer(5){EM::stop}
      end
    end
  end
  
  wb.disconnected = Proc.new do
    puts "Disconnected"
  end

  wb.run
end