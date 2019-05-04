require_relative "select"

module DatTool
  class CLI < Thor
    desc "select PATH INPUT OUTPUT", "Create backup from archive"
    def select(path, input, output)
      select = Select.new(path, input, output)
      select.select
    end
  end
end
