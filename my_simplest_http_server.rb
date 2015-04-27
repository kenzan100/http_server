require 'socket'
require 'uri'

class ReactTutorial
  def self.insert_comment(msg_body)
    comment = parse_comment(msg_body)
    File.open('public/comments.json', 'r+') do |file|
      beginning_of_last_line_pos = 0
      file.each { beginning_of_last_line_pos = file.pos unless file.eof? }
      file.seek(beginning_of_last_line_pos, IO::SEEK_SET)
      file.puts comment
      file.puts ']'
    end
  end

  def self.parse_comment(msg_body)
    msg = ',{'
    msg_body.split('&').each do |elem|
      k, v = elem.split('=')
      msg << "\"#{k}\":\"#{v}\","
    end
    msg[-1] = '}'
    msg
  end
end

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

      if req_line.split(" ").first == 'POST'
        msg_body = read_msg_body(socket)
        ReactTutorial.insert_comment(msg_body)
        next
      end

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

  def insert_comment(msg_body)
    # File.open(comments.json, 'w') do |file|
    #  insert parsed_msg_body
    # end
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

  def read_msg_body(socket)
    body_length = 0
    socket.each_line("\r\n") do |header|
      if header.match(/Content-Length/)
        body_length = header.match(/[0-9]./)[0].to_i
      end
      break if header == "\r\n"
    end
    socket.read body_length
  end
end

server = MyHTTPServer.new
server.start
