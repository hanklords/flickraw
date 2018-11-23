class Flickr
  class Error < StandardError; end

  class FlickrAppNotConfigured < Error; end

  class FailedResponse < Error
    attr_reader :code
    alias :msg :message
    def initialize(msg, code, req)
      @code = code
      super("'#{req}' - #{msg}")
    end
  end

end
