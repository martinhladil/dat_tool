#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require_relative "dat_tool/cli"

begin
  DatTool::CLI.start(ARGV)
end
