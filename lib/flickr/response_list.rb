class Flickr
  class ResponseList < Response

    include Enumerable

    def initialize(h, t, a); super(h, t); @a = a end

    def [](k); k.is_a?(Integer) ? @a[k] : super(k) end

    def each
       @a.each { |e| yield e }
    end

    def to_a; @a end

    def inspect; @a.inspect end

    def size; @a.size end

    def map!
      @a = @a.map { |e| yield e }
    end

    def marshal_dump; [@h, @flickr_type, @a] end

    alias length size

  end
end
