#!ruby 
#-*- encoding: utf-8 -*-
require 'rubygems'
require 'timelog4r'
require 'sixamo'

config = open('config.yml', 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user]
t.password = config[:password]
t.user_agent = config[:agent]
sixamo = Sixamo.new('dict')

first_memo = t.get_friends_timeline(:cnt=>1)[:entries].first[:memo_text]
text = sixamo.talk(first_memo)
sleep 10
t.update(text)

