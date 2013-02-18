require 'json'
require 'active_support/core_ext/hash'

class MakeSure
  def self.config=(config)
    @config = config
  end

  def self.config
    @config ||= {}
  end

  module HTTPHelpers
    class JSONHashResponse < DelegateClass(Hash)
      attr_reader :code
      def initialize(hash, code)
        @code = code
        super(hash.with_indifferent_access)
      end
    end

    class JSONArrayResponse < DelegateClass(Array)
      attr_reader :code
      def initialize(array, code)
        @code = code
        super(array)
      end
    end

    def request(*args)
      defaults = MakeSure.config[:defaults] || {}
      opts_i = args[2].is_a?(String) ? 3 : 2
      args[opts_i] ||= {} if defaults
      args[opts_i].reverse_merge!(defaults) 
      RestClient.send(*args)
    rescue RestClient::Exception => e
      e.response
    end

    classes = {
      Hash => JSONHashResponse,
      Array => JSONArrayResponse
    }

    [:get, :put, :post, :delete, :head].each do |verb|
      self.send(:define_method, verb) do |*args|
        out = [verb, "#{MakeSure.config[:base_url]}#{args[0]}"] +  args[1..-1]
        response = request(*out)
        begin 
          json = JSON.parse(response)
          classes[json.class].new(json, response.code)
        rescue JSON::ParserError
          response
        end
      end
    end
  end
end
