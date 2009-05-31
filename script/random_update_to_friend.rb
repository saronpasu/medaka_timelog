#!ruby -Ku
#-*- encoding: utf-8 -*-

require 'rubygems'
require 'timelog4r'
require 'lib/sixamo'
require 'lib/medaka'
require 'yaml'

include Medaka

CONFIG_FILE = 'config.yml'
FRIEND_LIST_FILE = 'list/friend_list.yml'
SIXAMO_DICT = 'dict'

config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
friend_list = open(FRIEND_LIST_FILE, 'r'){|f|YAML::load(f.read)}
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

active_friends = t.get_friends_timeline(:cnt=>20)[:entries].map.reject{|st|st[:author][:user_id].eql?(config[:user_id])}
res_target = active_friends[rand(active_friends.size)]
sixamo = Sixamo.new(SIXAMO_DICT)
res_header = '/P @'+res_target[:author][:user_id]+' '
res_body = sixamo.talk(res_target[:memo_text])
friends = friend_list[rand(friend_list.size-10)..10]
res_body = name_replace(res_body, res_target[:author][:user_name], friends)
res = URI.escape(res_header+res_body)

sleep 10
#p res_header+res_body
t.update(res)

