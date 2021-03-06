#coding: utf-8
# Author: Memaizaka 2011
# Created: 2011/08/06

require 'net/http'
require 'json'
require_relative 'bouyomi_socket'

if ARGV.size < 1
  $stderr.puts "少なくともstream_nameを引数に入れてください"
  $stderr.puts "stream_name startnum get_single_comment?"
  $stderr.puts "ex: AAAAAAAAAAAAAAAAAAAAAAAAA 1 true"
else
  query = "stream_name=#{ARGV[0]}"
  from = "&comment_num=%s" % (ARGV[1] || '1')
  single = ARGV[2] ?  "&single=#{ARGV[2]}" : ''
  query << from << single
  
  comment = Struct.new("Comment", :name, :message, :time, :num)
  
  comments = []
  Net::HTTP.version_1_2
  Net::HTTP.start 'gae.cavelis.net' do |http|
    res = http.post('/viewedit/getcomment', query)
    JSON.parse(res.body).each do |k,v|
      case k
        when /num_(\d+)/
          comments << comment.new(v['name'], v['message'], v['time'], v['comment_num'])
        else
          puts "#{k} => #{v}"
      end
    end
  end
  
  comments.sort_by! {|c| c.num}
  
  b = BouyomiSocket.new
  
  comments.each do |c|
    m = c.num.to_s + "番\n"
    m << c.name << "さん\n" unless c.name == ''
    m << c.message
    b.talk(m)
  end
end
