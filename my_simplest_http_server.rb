# whis work is made by this website,
# https://practicingruby.com/articles/implementing-an-http-file-server
# my intension is a pure study.
#
# Below is a Ruby implementation of http request/responce
# 1. browser issues an HTTP request by opening a TCP socket connection,
#    if the server accepts it, it opens a socket for bi-directional communication.
# 2. when the connection is made, the HTTP client sends a HTTP request, like
#    GET /file.txt HTTP/1.1
#    User-Agent: ExampleBrowser/1.0
#    Host: example.com
#    Accept: */*
# 3. the server parses the request.
# 4. with the same connection, the server sends back the response.
#    HTTP/1.1 200 OK
#    Content-Type: text/plain
#    Content-Length: 13
#    Connection: close
#
#    hello world
# 5. after finish the response, the server closes the socket to terminate the connection.

# This provides TCPServer and TCPSocket classes
require 'socket'

# Initialize a TCPSserver obj that listens on localhost:2345 for incoming connections.
server = TCPServer.new 'localhost', 2345

loop do
  # when a client connects, return a TCPSocket obj
  # it's a subclass of IO class..
  socket = server.accept

  # read the first line of the request(presumably the Request-Line)
  request = socket.gets

  # log the request to the console
  STDERR.puts request

  response = "Hi World!!\n"

  # need to include the Content-Type and Content-Length headers
  # to let the client know the size and type of data in the response.
  # be careful that HTTP is whitespace sensitive,
  # and expects each header line to end with CRLF.
  socket.print "HTTP/1.1 200 OK\r\n" +
    "Content-Type: text/plain\r\n" +
    "Content-Length: #{response.bytesize}\r\n" +
    "Connection: close\r\n"

  # print a blank line to separete the header from the msg body
  socket.print "\r\n"

  # print the actual response body.
  socket.print response

  # close the socket, terminating the connection.
  socket.close
end
