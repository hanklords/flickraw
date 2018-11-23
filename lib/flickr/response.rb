class Flickr
  class Response

    attr_reader :flickr_type

    def self.build(h, type) # :nodoc:
      if h.is_a? Response
        h
      elsif type =~ /s$/ and (a = h[$`]).is_a? Array
        ResponseList.new(h, type, a.collect { |e| Response.build(e, $`) })
      elsif h.keys == ['_content']
        h['_content']
      else
        Response.new(h, type)
      end
    end

    def initialize(h, type) # :nodoc:
      @flickr_type, @h = type, {}
      methods = 'class << self;'
      h.each do |k, v|
        @h[k] = case v
                when Hash  then Response.build(v, k)
                when Array then v.collect { |e| Response.build(e, k) }
                else v
                end
        methods << "def #{k}; @h['#{k}'] end;" if Util.safe_for_eval?(k)
      end
      eval methods << 'end'
    end
    def [](k); @h[k] end
    def to_s; @h['_content'] || super end
    def inspect; @h.inspect end
    def to_hash; @h end
    def marshal_dump; [@h, @flickr_type] end
    def marshal_load(data); initialize(*data) end
  end
end
