Gem::Specification.new do |spec|
  spec.name         = "trovobot"
  spec.version      = "0.1.2"
  spec.summary      = "Trovo Live API client"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/trovobot"}

  spec.required_ruby_version = ">=3"

  spec.add_dependency "nethttputils", "~>0.4.3.2"
  spec.add_dependency "async-http"
  spec.add_dependency "async-websocket"

  spec.files        = %w{ LICENSE trovobot.gemspec lib/trovobot.rb lib/trovobot/common.rb }
end
