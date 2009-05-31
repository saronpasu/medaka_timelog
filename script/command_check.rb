#!ruby -Ku
#-*- encoding: utf-8 -*-

require 'yaml'
require 'rubygems'
require 'timelog4r'
require 'lib/medaka'

include Medaka
CONFIG_FILE = 'config.yml'
COMMAND_CHECK_FILE = 'list/command_checked.yml'
COMMAND_STACK_FILE = 'list/command_stack.yml'

config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

checked_list = open(COMMAND_CHECK_FILE, 'r'){|f|YAML::load(f.read)}
command_stack = open(COMMAND_STACK_FILE, 'r'){|f|YAML::load(f.read)}

messages = t.get_direct_message(:cnt=>50)[:entries].reject{|ms|ms[:author][:user_id].eql(config[:user_id])}

command_stac += messages.select{|ms|
  find_command(ms[:memo_text])
}.reject{|ms|
  checked_list.include?(ms[:memo_id])
}
command_stack.uniq!
open(COMMAND_STACK_FILE, 'w'){|f|f.print(command_stack.to_yaml)}


