module FlickRaw
  module Util
    extend self

    def sanitize(string)
      string.gsub(/\W+/, '_') if string
    end

    def safe_for_eval?(string)
      string == sanitize(string)
    end

  end
end
