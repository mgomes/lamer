# frozen_string_literal: true

require "ffi"

class Lamer
  module FFI
    extend ::FFI::Library

    LIBRARY_NAMES = case RbConfig::CONFIG["host_os"]
    when /darwin/
      %w[libmp3lame.dylib libmp3lame.0.dylib]
    when /linux/
      %w[libmp3lame.so.0 libmp3lame.so]
    when /mswin|mingw/
      %w[libmp3lame.dll mp3lame.dll lame_enc.dll]
    else
      %w[libmp3lame.so libmp3lame.dylib mp3lame]
    end.freeze

    begin
      ffi_lib LIBRARY_NAMES
    rescue LoadError => e
      raise LoadError, "Could not load libmp3lame. Please install LAME (e.g., `brew install lame` on macOS). Original error: #{e.message}"
    end
  end
end
