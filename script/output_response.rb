#!ruby
#-*- encoding: utf-8 -*-
require 'timelog4r'
require 'yaml'

config = open('config.yml', 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

REPLY_LIST = 'reply_list.yml'
list = t.get_reply_list(:cnt=>50)[:entries]
file = open(REPLY_LIST, 'r'){|f|YAML::load(f.read)}
open(REPLY_LIST, 'w'){|f|f.print((list | file).to_yaml)}

