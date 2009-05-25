#!ruby
#-*- encoding: utf-8 -*-

require 'rubygems'
require 'timelog4r'
require 'yaml'
require 'sixamo'

CONFIG_FILE = 'config.yml'
config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

RESPONSE_FILE = 'list/response_list.yml'
res_list = open(RESPONSE_FILE, 'r'){|f|YAML::load(f.read)}
res_target = res_list.unshift
open(RESPONSE_FILE, 'w'){|f|f.print(res_list.to_yaml)}

sixamo = Sixamo.new('dict')
res_header = res_target[:author][:user_id]
res_body = sixamo.talk(res_target[:memo_text])
# name_replace(res_body, pattern, target)

t.update(res_header+' '+res_body)
