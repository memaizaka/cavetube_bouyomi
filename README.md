Cavetube用の棒読みちゃん連携や投稿スクリプト練習です。
==================================================
bouyomi.rb or bouyomi_2.rb / bouyomi_socket.rb
--------------------------------------------------
・コメントの番号よみ、名前よみ、メッセージを同期的に読む方法を模索した実験

cavetube_post_test.rb
--------------------------------------------------
・文字コードの問題で入力コンソールがUTF-8じゃないと化けます

bouyomi3.rb / socket_io.rb / bouyomi_em_socket.rb
--------------------------------------------------
・これが最新
・socket.ioの部分を分離してみました
・使い方
* ruby bouyomi_3.rb "stream_name"
* stream_nameを入れないとTOPから配信の開始/終了情報を取ってくる