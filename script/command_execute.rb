#!ruby -Ku
#-*- encoding: utf-8 -*-

require 'lib/medaka'
require 'rubygems'
require 'timelog4r'
require 'yaml'

include Medaka

COMMAND_STACK_FILE = 'list/command_stack.yml'
COMMAND_CHECK_FILE = 'list/command_checked.yml'
CONFIG_FILE = 'config.yml'

config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}

t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

command_stack = open(COMMAND_STACK_FILE, 'r'){|f|YAML::load(f.read)}
command_checked = open(COMMAND_CHECKED_FILE, 'r'){|f|YAML::load(f.read)}

command_target = command_stack.pop
open(COMMAND_STACK_FILE, 'w'){|f|f.print(command_stack.to_yaml)}

command = find_command(command_target[:memo_text])
m = Command.method(command[:name])
res_body = m.call
res_body = name_replace(res_body, command_target[:author][:user_name]) if command[:type].eql(:response)

res_header = ''
case command[:output]
  when :status
    res_header += '/P '
  when :message
    res_header += '/d '
end
res_header += '@'+command_target[:author][:user_id]+' '

res = res_header+res_body
t.update(URI.escape(res))

command_checked += command_target[:memo_id]
command_checked.uniq!
open(COMMAND_CHECKED_FILE, 'w'){|f|f.print(command_checked.to_yaml)}


