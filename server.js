var http = require("http");
var server = http.createServer();

// socket.ioの準備
var io = require('socket.io').listen(server);

server.listen(8080,()=>{
    console.log("server run")
});

// クライアント接続時の処理
io.on('connection', function(socket) {
    console.log("client connected!!")

    // クライアント切断時の処理
    socket.on('disconnect', function() {
        console.log("client disconnected!!")
    });
    // クライアントからの受信を受ける (socket.on)
    socket.on("from_client", function(obj){
        console.log(obj)
    });
});

// とりあえず一定間隔でサーバ時刻を"全"クライアントに送る (io.emit)
// var send_servertime = function() {
//     var now = new Date();
//     io.emit("from_server", now.toLocaleString());
//     console.log(now.toLocaleString());
//     setTimeout(send_servertime, 5000)
// };
// send_servertime();

//server.listen(8080);

//サーバー起動。listen()メソッドを実行して3000番ポートで待ち受けする。
// app.listen(3000, function () {
//   console.log('listening on port 3000');
// });






