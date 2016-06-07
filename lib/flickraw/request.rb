module FlickRaw
class Request
  def initialize(flickr = nil) # :nodoc:
    @flickr = flickr

    self.class.flickr_objects.each {|name|
      klass = self.class.const_get name.capitalize
      instance_variable_set "@#{name}", klass.new(@flickr)
    }
  end

  def self.build_request(req) # :nodoc:
    method_nesting = req.split '.'
    raise "'#{@name}' : Method name mismatch" if method_nesting.shift != request_name.split('.').last

    if method_nesting.size > 1
      name = method_nesting.first
      class_name = name.capitalize
      if flickr_objects.include? name
        klass = const_get(class_name)
      else
        klass = Class.new Request
        const_set(class_name, klass)
        attr_reader name
        flickr_objects << name
      end

      klass.build_request method_nesting.join('.')
    else
      req = method_nesting.first
      module_eval %{
        def #{req}(*args, &block)
          @flickr.call("#{request_name}.#{req}", *args, &block)
        end
      } if Util.safe_for_eval?(req)
      flickr_methods << req
    end
  end

  # List the flickr subobjects of this object
  def self.flickr_objects; @flickr_objects ||= [] end

  # List the flickr methods of this object
  def self.flickr_methods; @flickr_methods ||= [] end

  # Returns the prefix of the request corresponding to this class.
  def self.request_name; name.downcase.gsub(/::/, '.').sub(/[^\.]+\./, '') end
end

end
