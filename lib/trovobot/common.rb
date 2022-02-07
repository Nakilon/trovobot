# this might some day before a separate gem

module TrovoBot
  module Common
    require "fileutils"
    def self.cache_text filename, update = false
      if !update && File.exist?(filename)
        File.read filename
      else
        yield.tap{ |_| FileUtils.mkdir_p File.dirname filename; File.write filename, _ }
      end
    end
  end
end
