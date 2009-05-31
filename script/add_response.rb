#!ruby
#-*- encoding: utf-8 -*-

require 'rubygems'
require 'timelog4r'
require 'yaml'
require 'lib/sixamo'
require 'lib/medaka'
include Medaka

CONFIG_FILE = 'config.yml'
config = open(CONFIG_FILE, 'r'){|f|YAML::load(f.read)}
t = Timelog4r.new
t.user_id = config[:user_id]
t.password = config[:password]
t.user_agent = config[:agent]

RESPONSE_FILE = 'list/reply_list.yml'
RESPONSED_FILE = 'list/responsed.yml'
FRIENDS_FILE = 'list/friend_list.yml'

res_list = open(RESPONSE_FILE, 'r'){|f|YAML::load(f.read)}
responsed = open(RESPONSED_FILE, 'r'){|f|YAML::load(f.read)}
friend_list = open(FRIENDS_FILE, 'r'){|f|YAML::load(f.read)}
res_target = res_list.shift
open(RESPONSE_FILE, 'w'){|f|f.print(res_list.to_yaml)}

sixamo = Sixamo.new('dict')
res_header = '/P @'+res_target[:author][:user_id]
res_body = sixamo.talk(res_target[:memo_text])
friends = friend_list[rand(friend_list.size-10)..10]
res_body = name_replace(res_body, res_target[:author], friends)

# p res_header+' '+res_body
res = URI.escape(res_header+' '+res_body)
t.update(res)

responsed.push(res_target[:memo_id])
open(RESPONSED_FILE, 'w'){|f|f.print(responsed.to_yaml)}

