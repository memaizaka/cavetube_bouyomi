#coding : utf-8

# ワンラインコメントを投稿できます
# 最初にstream_name(room_name)を入力してください

# コマンドラインの文字コードがUTF-8じゃないとコメが化ける
# kconvで暫定修正
require 'eventmachine'
require 'em-http-request'
require 'json'
require 'kconv'

# 暫定これでどうだ　だめだった
p $stdin.set_encoding("Windows-31J", "UTF-8") if Encoding.default_external == "Windows-31J"

class PostClient < EM::Connection
  include EM::P::LineText2
  
  attr_reader :stream_name
  
  def initialize
    puts "enter stream_name"
    put_prompt
  end
  
  def put_prompt
    print ">>"
  end
  
  def receive_line(data)
    if @stream_name
      p data.encoding #このdataはどっから来てるのか…
      msg = {name:'from script', stream_name:@stream_name, message:data.toutf8}
      http = EM::HttpRequest.new('http://gae.cavelis.net/viewedit/postcomment').post :body => msg
      http.callback do
        res = JSON.parse http.response
#        res.each do |k,v|
#          p "#{k} => #{v}"
#        end
        # puts "post succeeded" if res['ret']
        put_prompt
      end
      http.errback do
        #error対応なし
        p http.response
      end
    else
      @stream_name = data
      put_prompt
    end
  end
end

EM.run do
    EM.open_keyboard(PostClient)
end
