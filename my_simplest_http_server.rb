require 'socket'
require 'uri'

class MyHTTPServer
  WEB_ROOT = './public'

  CONTENT_TYPE_MAPPING = {
    html: 'text/html',
    txt:  'text/plain',
    png:  'image/png',
    jpg:  'image/jpeg',
    json: 'application/json'
  }

  # defaults to binary data
  DEFAULT_CONTENT_TYPE = 'application/octet-stream'

  def initialize
    @server = TCPServer.new 'localhost', 2345
  end

  def start
    loop do
      socket = @server.accept
      req_line = socket.gets

      STDERR.puts req_line

      # make an actual path from request line
      path = requested_file req_line
      # defaults to index.html if endpoint is directory
      path = File.join(path,'index.html') if File.directory?(path)

      if File.exists?(path) && !File.directory?(path)
        File.open(path, "rb")  do |file|
          socket.print "HTTP/1.1 200 OK\r\n" +
            "Content-Type: #{content_type(file)}\r\n" +
            "Content-Length: #{file.size}\r\n" +
            "Connection: close\r\n"

          socket.print "\r\n"

          # write the contents of the file to the socket
          IO.copy_stream file, socket
        end
      else
        msg = "File not found\n"

        socket.print "HTTP/1.1 404 Not Found\r\n" +
          "Content-Type: text/plain\r\n" +
          "Content-Length: #{msg.size}\r\n" +
          "Connection: close\r\n"

        socket.print "\r\n"

        socket.print msg
      end

      socket.close
    end
  end

  def content_type(path)
    extension = File.extname(path).split(".").last
    CONTENT_TYPE_MAPPING.fetch extension.to_sym, DEFAULT_CONTENT_TYPE
  end

  def requested_file(request_line)
    request_uri = request_line.split(" ")[1]
    path = URI.unescape(URI(request_uri).path)

    clean = []
    parts = path.split("/")
    parts.each do |part|
      next if part.empty? || part == '.'
      part == '..' ? clean.pop : clean << part
    end

    File.join(WEB_ROOT, *clean)
  end
end

server = MyHTTPServer.new
server.start
