#!ruby
#-*- encoding: utf-8 -*-
require 'yaml'

module Medaka
  NAME_PATTERN_FILE = 'list/name_pattern.yml'
  EMOJI_PATTERN_FILE = 'list/emoji_pattern.yml'
  FRIEND_LIST_FILE = 'list/friend_list.yml'
  COMMAND_PATTERN_FILE = 'list/command_pattern.yml'

  def init_name_pattern
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    pattern = open(NAME_PATTERN_FILE, opt){|f|YAML::load(f.read)}
    return Regexp.compile(pattern)
  end

  def name_replace(text, target, friends = nil)
    name_pattern = init_name_pattern()
    matched = text.scan(name_pattern)
    return text if matched.empty?
    matched.flatten!;matched.uniq!;matched.compact!
    if friends then
      replace = friends.map{|friend|friend[:user_name]}.unshift(target[:user_name])
    else
      replace = [target[:user_name]]
    end
    replace = (replace - matched)[0..matched.size-1]
    h = Hash.new(replace.first)
    replace.each do |i|
      h[matched.shift] = i
    end
    result = text.gsub(name_pattern){|m|h[m]}
    return result
  end

  def init_emoji_pattern
  end

  def to_emoji(text)
  end

  def init_command_list
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    command_list = open(COMMAND_PATTERN_FILE, opt){|f|YAML::load(f.read)}
    command_list.map! do |command|
      {
        :name => command[:name],
        :pattern => Regexp.compile(command[:pattern]),
        :type => command[:type],
        :output => command[:output]
      }
    end unless command_list.empty?
    return command_list
  end

  def find_command(text)
    command_list = init_command_list
    result = command_list.find{|comm|comm[:pattern].match(text)}
    return result
  end

  autoload :Command, 'lib/medaka/command.rb'
end

