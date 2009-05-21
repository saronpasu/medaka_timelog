#!ruby
#-*- encoding: utf-8 -*-
require 'timelog4r'
require 'yaml'

config = open('config.yml', 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id}
t.password = config[:password]
t.user_agent = config[:agent]

FRIEND_LIST = 'friend_list.yml'
file = open(FRIEND_LIST, 'r'){|f|YAML::load(f.read)}
list = t.get_friend_list[:entries]
open(FRIEND_LIST, 'w'){|f|f.print((list | file).to_yaml)}


