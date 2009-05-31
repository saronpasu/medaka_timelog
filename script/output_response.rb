#!ruby
#-*- encoding: utf-8 -*-
require 'rubygems'
require 'timelog4r'
require 'yaml'

CONFIG_FILE = 'config.yml'

config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

REPLY_LIST = 'list/reply_list.yml'
list = t.get_reply_list(:cnt=>50)[:entries]
file = open(REPLY_LIST, 'r'){|f|YAML::load(f.read)}
open(REPLY_LIST, 'w'){|f|f.print((list | file).to_yaml)}

