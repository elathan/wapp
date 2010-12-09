require 'rubygems'
require 'webrick'
require 'erubis'


def initCookies (request, response)
  cookiePresent = false

  request.cookies.length.times do |i|
    if (request.cookies[i].name.eql?("loginCookie") == true)
      cookiePresent = true
      break
    end
  end

  if (cookiePresent == true)
    response.cookies.replace(request.cookies)
  else
    myCookie = WEBrick::Cookie.new("loginCookie", "anonymous")
    response.cookies << myCookie
  end
  
  return response
end


def resetCookies (request, response)
  until request.cookies.empty?
    request.cookies.pop
  end
  return initCookies(request, response)
end


def cookiesArrayToHash (cookies)
  myHash = Hash.new()
  cookies.length.times do |i|
    myHash.store(cookies[i].name, cookies[i].value)
  end
  return myHash
end


class Page
  
  def initialize(filename, parameters)
    @filename, @parameters = filename, parameters
    self.load()
  end
  
  def load()
    @body = File.open(@filename).read()
    @template = Erubis::Eruby.new(@body)
  end
  
  def render()
    @template.result(@parameters)
  end
end


class Logout < WEBrick::HTTPServlet::AbstractServlet
  def do_GET (request, response)
    response = resetCookies(request, response)
    response.set_redirect(WEBrick::HTTPStatus::MovedPermanently, "/")
  end
end


class Login < WEBrick::HTTPServlet::AbstractServlet

  def do_GET (request, response)

    username = request.query["username"]
    #password = request.query["password"]

    if (!username.eql?("")) #&& !password.eql?(""))
      myCookie = WEBrick::Cookie.new("loginCookie", username)
      response.cookies << myCookie
    else
      response.cookies.replace(request.cookies)
    end

    response.set_redirect(WEBrick::HTTPStatus::MovedPermanently, "/")
  end

end


class Main < WEBrick::HTTPServlet::AbstractServlet
 
  # Process the request, return response
  def do_GET(request, response)

    #
    response = initCookies(request, response)
    #

    status, content_type, body = page(response)

    response.status = status
    response['Content-Type'] = content_type
    response.body = body
  end
 
  def page(response)
    page = Page.new('pages/index.html', cookiesArrayToHash(response.cookies))
    html = page.render()
    return 200, "text/html", html
  end
end


server = WEBrick::HTTPServer.new(:Port => 8000)
server.mount("/css", WEBrick::HTTPServlet::FileHandler, './css')
server.mount("/", Main)
server.mount("/login", Login)
server.mount("/logout", Logout)

trap "INT" do 
  server.shutdown() 
end

server.start()
