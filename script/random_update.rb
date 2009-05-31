#!ruby 
#-*- encoding: utf-8 -*-
require 'rubygems'
require 'timelog4r'
require 'yaml'
require 'lib/sixamo'

CONFIG_FILE = 'config.yml'
SIXAMO_DICT = 'dict'

config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]
sixamo = Sixamo.new(SIXAMO_DICT)

first_memo = t.get_friends_timeline(:cnt=>1)[:entries].first[:memo_text]
header = "/P "
text = sixamo.talk(first_memo)
sleep 10
text = header+text
t.update(text)

