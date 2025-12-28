# frozen_string_literal: true

require_relative "lib/lamer/version"

Gem::Specification.new do |spec|
  spec.name = "lamer"
  spec.version = Lamer::VERSION
  spec.authors = ["Mauricio Gomes"]
  spec.email = ["mauricio@edge14.com"]

  spec.summary = "Ruby FFI bindings for the LAME MP3 encoder"
  spec.description = "Native Ruby bindings to libmp3lame via FFI. Encode audio to MP3 directly from Ruby without shelling out."
  spec.homepage = "https://github.com/mgomes/lamer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "README.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
