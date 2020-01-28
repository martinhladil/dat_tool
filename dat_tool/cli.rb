require_relative "select"
require_relative "no_pay_station_select"

module DatTool
  class CLI < Thor
    desc "select PATH INPUT OUTPUT", "Create DAT file only for the existing files"
    def select(path, input, output)
      select = Select.new(path, input, output)
      select.select
    end

    desc "no_pay_station_select PATH INPUT OUTPUT", "Create DAT file from NoPayStation file only for the existing files"
    def no_pay_station_select(path, input, output)
      no_pay_station_select = NoPayStationSelect.new(path, input, output)
      no_pay_station_select.no_pay_station_select
    end
  end
end
