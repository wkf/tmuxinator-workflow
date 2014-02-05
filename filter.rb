require 'logger'
require './alfred'
require './sources/tmux'

Alfred.logger = Logger.new('development.log')
Alfred.filter(*ARGV)
