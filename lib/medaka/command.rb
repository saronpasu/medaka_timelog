#!ruby -Ku
#-*- encoding: utf-8 -*-

require 'yaml'
require 'lib/sixamo'

module Medaka::Command
  VERSON = Module.new do
    MAJOR = 1,
    MINOR = 0,
    TINY = 0

    def self.to_s
      [MAJOR, MINOR, TINY].join('.')
    end
  end

  OYATSU_LIST_FILE = 'list/oyatsu_list.yml'
  OYATSU_TEMPLATE_FILE = 'list/oyatsu_template.yml'
  URANAI_LIST_FILE = 'list/uranai_list.yml'
  URANAI_TEMPLATE_FILE = 'list/uranai_template.yml'
  HELP_TEMPLATE_FILE = 'list/help_template.yml'
  VERSION_TEMPLATE_FILE = 'list/version_template.yml'
  SIXAMO_DICT = 'dict'

  def init_oyatsu_list
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    list = open(OYATSU_LIST_FILE, opt){|f|YAML::load(f.read)}
    return list
  end

  def init_oyatsu_template
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    list = open(OYATSU_TEMPLATE_FILE, opt){|f|YAML::load(f.read)}
    return list
  end

  def oyatu
    oyatsu_list = init_oyatsu_list
    oyatsu_template = init_oyatsu_template_list
    oyatsu = oyatsu_list[rand(oyatsu_list.size)]
    template = oyatsu_template[rand(oyatsu_template.size)]
    result = template.sub(/:oyatsu:/, oyatsu)
    return result
  end

  def init_uranai_list
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    list = open(URANAI_LIST_FILE, opt){|f|YAML::load(f.read)}
    return list
  end

  def init_uranai_template
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    template = open(URANAI_TEMPLATE_FILE, opt){|f|YAML::load(f.read)}
    return template
  end

  def uranai
    uranai_list = init_uranai_list
    uranai_template = init_uranai_template
    uranai = uranai_list[rand(uranai_list.size)]
    template = uranai_template[rand(uranai_template.size)]
    sixamo = Sixamo.new(SIXAMO_DICT)
    luckey_word = sixamo.talk
    result = template.sub(/:uranai:/, uranai)
    result.sub!(/:luckey_word:/, luckey_word)
    return result
  end

  def help
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    return open(HELP_TEMPLATE_FILE, opt){|f|YAML::load(f.read)}
  end

  def version
    if String.allocate.respond_to? :encoding then
      opt = 'r:utf-8'
    else
      opt = 'r'
    end
    result = open(VERSION_TEMPLATE_FILE, opt){|f|YAML::load(f.read)}
    result.sub!(/:version:/, VERSION.to_s)
  end
end

