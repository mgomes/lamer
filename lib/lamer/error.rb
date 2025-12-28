# frozen_string_literal: true

class Lamer
  class Error < StandardError; end
  class EncodingError < Error; end
  class DecodingError < Error; end
  class ConfigurationError < Error; end
end
