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

FRIEND_LIST = 'list/friend_list.yml'
file = open(FRIEND_LIST, 'r'){|f|YAML::load(f.read)}
list = t.get_memofriend_list(:cnt=>'all')[:entries]
open(FRIEND_LIST, 'w'){|f|f.print((list | file).to_yaml)}


