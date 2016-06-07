module FlickRaw
class Response
  def self.build(h, type) # :nodoc:
    if h.is_a? Response
      h
    elsif type =~ /s$/ and (a = h[$`]).is_a? Array
      ResponseList.new(h, type, a.collect {|e| Response.build(e, $`)})
    elsif h.keys == ["_content"]
      h["_content"]
    else
      Response.new(h, type)
    end
  end

  attr_reader :flickr_type
  def initialize(h, type) # :nodoc:
    @flickr_type, @h = type, {}
    methods = "class << self;"
    h.each {|k,v|
      @h[k] = case v
        when Hash  then Response.build(v, k)
        when Array then v.collect {|e| Response.build(e, k)}
        else v
      end
      methods << "def #{k}; @h['#{k}'] end;" if Util.safe_for_eval?(k)
    }
    eval methods << "end"
  end
  def [](k); @h[k] end
  def to_s; @h["_content"] || super end
  def inspect; @h.inspect end
  def to_hash; @h end
  def marshal_dump; [@h, @flickr_type] end
  def marshal_load(data); initialize(*data) end
end

class ResponseList < Response
  include Enumerable
  def initialize(h, t, a); super(h, t); @a = a end
  def [](k); k.is_a?(Fixnum) ? @a[k] : super(k) end
  def each; @a.each{|e| yield e} end
  def to_a; @a end
  def inspect; @a.inspect end
  def size; @a.size end
  def marshal_dump; [@h, @flickr_type, @a] end
  alias length size
end

class FailedResponse < Error
  attr_reader :code
  alias :msg :message
  def initialize(msg, code, req)
    @code = code
    super("'#{req}' - #{msg}")
  end
end

end
