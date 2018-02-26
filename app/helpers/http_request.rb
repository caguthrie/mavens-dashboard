module HttpRequest
  def HttpRequest.get(url)
    url = URI.parse(url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    if res.code.to_i > 399
      raise 'Unable to contact server successfully'
    else
      JSON.parse res.body
    end
  end
end
