#!/usr/bin/env ruby
#-*- coding: UTF-8 -*-
#
# sixamo.rb
# $Id: sixamo.rb,v 1.52 2007/03/05 08:31:23 hori Exp hori $
#

if RUBY_VERSION.match(/^1\.[678]/) then
	$KCODE = 'u'
end

# for ruby 1.6
unless [].respond_to?(:sort_by)

	module Enumerable
		def sort_by
			self.collect {|i| [yield(i), i]}.
				sort {|a,b| a[0] <=> b[0]}.
				collect! {|i| i[1]}
		end
	end

end

unless [].respond_to?(:inject)

	module Enumerable
		def inject(v)
			self.each do |elm|
				v = yield(v, elm)
			end
			v
		end
	end

end

class Array
	def sum
		first, *rest = self
		rest.inject(first) {|r,v| r+v}
	end
end

module Sixamo

	def Sixamo.new(*args)
		Sixamo::Core.new(*args)
	end

	def Sixamo.init_dictionary(dirname)

		dic = Dictionary.new(dirname)

		dic.load_text
		dic.learn_from_text(true)
		dic

	end


	module Util

		def Util.roulette_select(h)
			return nil if h.empty?

			sum = h.values.sum
			return Util.random_select(h.keys) if sum == 0

			r = rand*sum
			h.each do |key,value|
				r -= value
				return key if r <= 0
			end
			
			Util.random_select(h.keys)
		end


		def Util.random_select(ary)
			ary[rand(ary.size)]
		end


		def Util.message_normalize(str)
			paren_h = {}

			%w(「」 『』 （） ()).each do |paren|
				paren.scan(/./) do |ch|
					paren_h[ch] = paren.scan(/./)
				end
			end

			re = /[「」『』()（）]/
			ary = str.scan(re)
			
			cnt = 0
			paren = ''
			str2 = str.gsub(re) do |ch|
				res = if cnt == ary.size-1 && ary.size % 2 == 1
								''
							elsif cnt % 2 == 0
								paren = paren_h[ch][1]
								paren_h[ch][0]
							else
								paren 
							end

				cnt += 1
				res
			end

			str2.gsub!(/「」/,'')
			str2.gsub!(/（）/,'')
			str2.gsub!(/『』/,'')
			str2.gsub!(/\(\)/,'')

			str2
		end

		def Util.markov(src,keywords,trie)
			mar = markov_generate(src,trie)
			result = markov_select(mar,keywords)

			result
		end

		MarkovKeySize = 2
		def markov_generate(src,trie)
			return '' if src.size == 0

			ary = trie.split_into_terms(src.join("\n")+"\n",true)

			size = ary.size
			ary.concat(ary[0,MarkovKeySize+1])

			table = {}
			size.times do |idx|
				key = ary[idx,MarkovKeySize]
				table[key] = [] unless table.key?(key)
				table[key] << ary[idx+MarkovKeySize]
			end

			uniq = {}
			backup = {}

			table.each do |k,v|
				if v.size == 1 
					uniq[k] = v[0]
				else
					backup[k] = table[k].dup
				end
			end

			key = ary[0,MarkovKeySize]
			result = key.join('')
			10000.times do

				if uniq.key?(key)
					str = uniq[key]
				else
					table[key] = backup[key].dup if table[key].size == 0

					idx = rand(table[key].size)
					str = table[key][idx]

					table[key][idx] = nil
					table[key].compact!
				end

				result << str
				key = (key.dup << str)[1,MarkovKeySize]
			end

			result
		end

		def markov_split(str)
			result = []

			while /\A(.{25,}?)([。、．，]+|[?!.,]+[\s　])[ 　]*/.match(str)
				match = Regexp.last_match
				m = match[1]
				m += match[2].gsub(/、/,'。').gsub(/，/,'．') if match[2]
				result << m
				str = match.post_match
			end
			result << str if str.size > 0

			result
		end

		def markov_select(result, keywords)
			tmp = result.split(/\n/) || ['']
			result_ary = tmp.collect { |str| markov_split(str) }.flatten.uniq

			result_ary.delete_if{|a| a.size == 0 || /\0/.match(a) }

			result_hash = {}
			trie = Trie.new(keywords.keys)
			result_ary.each do |str|
				terms = trie.split_into_terms(str).uniq
				result_hash[str] = terms.collect{ |kw| keywords[kw] }.sum || 0
			end

			if $DEBUG
				sum = result_hash.values.sum.to_f
				tmp = result_hash.sort_by{ |k,v| [-v,k] }
				puts "-(候補数: #{result_hash.size})----"
				tmp[0,10].each do |k,v|
					printf("%5.2f%%: %s\n", v/sum*100, k)
				end
			end

			result = Util.roulette_select(result_hash)
			result || ''
		end

		module_function :markov_select, :markov_generate, :markov_split
	end

	class Core

		def initialize(dirname)
			@dic = Dictionary.load(dirname)
		end

		def talk(str=nil,weight={})

			if str
				keywords = @dic.split_into_keywords(str)
			else
				text = @dic.text
				latest_text = if text.size < 10 then text else text[-10..-1] end
				keywords = Hash.new(0)
				latest_text.each do |str|
					keywords.each { |k,v| keywords[k] *= 0.5 }
					@dic.split_into_keywords(str).each { |k,v| keywords[k] += v }
				end
			end

			weight.keys.each do |kw|
				if keywords.key?(kw)
					if weight[kw] == 0
						keywords.delete(kw)
					else
						keywords[kw] *= weight[kw]
					end
				end
			end

			msg = message_markov(keywords)

			if $DEBUG
				sum = keywords.values.sum
				tmp = keywords.sort_by{|k,v| [-v,k] }
				puts "-(term)----"
				tmp.each do |k,v|
					printf " %s(%6.3f%%), ", k, v/sum*100
				end
				puts "\n----------"
			end

			msg
		end

		def memorize(lines)
			@dic.store_text(lines)
			if @dic.learn_from_text
				@dic.save_dictionary
			end
		end

		def message_markov(keywords)

			lines = []
			if keywords.size > 0

				if keywords.size > 10
					keywords.sort_by{|k,v| -v}[10..-1].each do |k,v|
						keywords.delete(k)
					end
				end
				sum = keywords.values.sum
				if sum > 0
					keywords.each { |k,v| keywords[k] = v/sum }
				end

				keywords.keys.collect do |kw| 
					ary = @dic.lines(kw).sort_by{ rand }
					ary[0,10].each do |idx|
						lines << idx
					end
				end.flatten
			end
			10.times { lines << rand(@dic.text.size) }
			lines.uniq!

			source = lines.collect do |k,v|
				@dic.text[k,5]
			end.sort_by{ rand }.flatten.compact.uniq

			msg = Util.markov(source, keywords, @dic.trie)
			msg = Util.message_normalize(msg)

			msg
		end
	end

	class Dictionary

		TEXT_FILENAME = 'sixamo.txt'
		DIC_FILENAME = 'sixamo.dic'

		def Dictionary.load(dirname)
			dic = Dictionary.new(dirname)
			dic.load_text
			dic.load_dictionary
			dic
		end

		LTL = 3
		def initialize(dirname=nil)
			@occur = {}
			@rel = {}
			@trie = Trie.new
			
			@dirname = dirname
			@text_filename = "#{@dirname}/#{TEXT_FILENAME}"
			@dic_filename  = "#{@dirname}/#{DIC_FILENAME}"
			@text = []

			@line_num = 0
		end

		def load_text
			return unless File.readable?(@text_filename)

			File.open(@text_filename) do |fp|
				fp.each do |line|
					line.chomp!

					@text << line
				end
			end
		end

		def load_dictionary
			return unless File.readable?(@dic_filename)

			File.open(@dic_filename) do |fp|

				# header
				fp.each do |line|
					line.chomp!

					case line
					when /^$/
						break
					when /line_num:\s*(.*)\s*$/i
						@line_num = $1.to_i
					else
						STDERR.puts " #{@dic_filename}:[Warning] Unknown_header #{line}"
					end
				end

				GC.disable
				
				# body
				fp.each do |line|
					line.chomp!
					word, num, sum, occur = line.split(/\t/)
					if occur

						@occur[word] = occur.split(/,/).collect { |l| l.to_i }
						add_term(word)
						@rel[word] = Hash.new(0)
						@rel[word][:num] = num.to_i
						@rel[word][:sum] = sum.to_i
						
					end
				end

				GC.enable
				GC.start

			end
		end

		def save_text
			tmp_filename = "#{@dirname}/sixamo.tmp.#{Process.pid}-#{rand(100)}"

			File.open(tmp_filename, 'w') do |fp|
				fp.puts @text
			end

			File.rename( tmp_filename, @text_filename )
		end

		def save_dictionary
			tmp_filename = "#{@dirname}/sixamo.tmp.#{Process.pid}-#{rand(100)}"

			File.open(tmp_filename, 'w') do |fp|
				fp.print self.to_s
			end

			File.rename( tmp_filename, @dic_filename )
		end

		WindowSize = 500
		def learn_from_text(progress=nil)

			modified = false

			read_size = 0
			buf_prev = []
			end_flag = false
			idx = @line_num

			while true
				buf = []

				if progress
					idx2 = read_size/WindowSize * WindowSize
					
					if idx2 % 100_000 == 0
						STDERR.printf "\n%5dk ", idx2/1000
					elsif idx2 % 20_000 == 0
						STDERR.print "*"
					elsif idx2 % 2_000 == 0
						STDERR.print "."
					end
				end
				
				tmp = read_size
				while tmp/WindowSize == read_size/WindowSize
					if idx >= @text.size
						end_flag = true
						break 
					end
					buf << @text[idx]
					tmp += @text[idx].size
					idx += 1
				end
				read_size = tmp

				break if end_flag

				if buf_prev.size > 0
					learn(buf_prev+buf, @line_num)
					modified = true
				
					@line_num += buf_prev.size
				end

				buf_prev = buf
			end
			STDERR.print "\n" if progress

			modified
		end

		def store_text(lines)
			ary = []
			case RUBY_VERSION
				when /^1\.[678]/ then
					lines.each do |line|
						ary << line.gsub(/\s+/, ' ').strip
					end
				when /^1\.9/ then
					lines.each_char do |line|
						ary << line.gsub(/\s+/, ' ').strip
					end
			end

			ary.each do |line|
				@text << line
			end

			File.open(@text_filename, 'a') do |fp|
				ary.each do |line|
					line.chomp!

					fp.puts line
				end
			end
		end

		def learn(lines,idx=nil)
			new_terms = Freq.extract_terms(lines,30)

			new_terms.each { |term| add_term(term) }

			if idx
				words_all = []
				lines.each_with_index do |line,i|
					num = idx + i
					words = split_into_terms(line)
					words_all.concat(words)
					words.each do |term|
						if @occur[term].empty? || num > @occur[term][-1]
							@occur[term] << num
						end
					end
				end

				weight_update(words_all)

				self.terms.each do |term|
					occur = @occur[term]
					size = occur.size
					
					if size < 4 && size > 0 && occur[-1]+size*150 < idx
						del_term(term)
					end
				end
			end
		end

		def split_into_keywords(str)
			result = Hash.new(0)
			terms = split_into_terms(str)

			terms.each do |w|
				result[w] += self.weight(w)
			end

			result
		end

		def split_into_terms(str,num=nil)
			@trie.split_into_terms(str,num)
		end

		def to_s
			result = ""

			# header
			result << "line_num: #{@line_num}\n"
			result << "\n"

			@occur.delete_if { |k,v| v.size == 0 }

			@occur.each { |k,v|	@occur[k] = v[-100..-1] if v.size > 100 }

			# body
			tmp = @occur.keys.sort_by do |k| 
				[-@occur[k].size, @rel[k][:num], k.length, k]
			end

			tmp.each do |k|
				result << format("%s\t\%s\t\%s\t%s\n", 
												 k,
												 @rel[k][:num],
												 @rel[k][:sum],
												 @occur[k].join(','))
			end

			result
		end

		def weight_update(words)
			width = 20

			words.each do |term|
				@rel[term] = Hash.new(0) unless @rel.key?(term)
			end

			size = words.size
			(size-width).times do |idx1|
				word1 = words[idx1]

				(idx1+1).upto(idx1+width) do |idx2|
					@rel[word1][:num] += 1 if word1 == words[idx2]
					@rel[word1][:sum] += 1
				end
			end

			(width+1).times do |idx1|
				word1 = words[-idx1]

				if word1
					(idx1-1).downto(1) do |idx2|
						@rel[word1][:num] += 1 if word1 == words[-idx2]
						@rel[word1][:sum] += 1
					end
				end
			end
		end

		def weight(word)
			if !@rel.key?(word) || @rel[word][:sum] == 0
				0
			else
				num = @rel[word][:num]
				sum = @rel[word][:sum].to_f
				num/(sum*(sum+100))
			end
		end

		def lines(word)
			@occur[word] || []
		end

		def terms
			@occur.keys
		end

		def add_term(str)
			@occur[str] = [] unless @occur.key?(str)
			@trie.add(str)
			@rel[str] = Hash.new(0) unless @rel.key?(str)
		end

		def del_term(str)
			occur = @occur[str]
			@occur.delete(str)
			@trie.delete(str)
			@rel.delete(str)
			
			tmp = split_into_terms(str)
			tmp.each { |w| @occur[w] = @occur[w].concat(occur).uniq.sort }
			weight_update(tmp) if tmp.size > 0
		end

		attr_reader :text, :trie
		
	end


	class Freq

		def Freq.extract_terms(buf,limit)
			Freq.new(buf).extract_terms(limit)
		end

		def initialize(buf)
			buf = buf.join("\0") if buf.kind_of?(Array)
			@buf = buf
		end
		
		def extract_terms(limit)
			terms = extract_terms_sub(limit)

			terms = terms.collect {|t,n| [t.reverse.strip,n] }.sort
			
			terms2 = []
			(terms.size-1).times do |idx|
				if terms[idx][0].size >= terms[idx+1][0].size ||
						terms[idx][0] != terms[idx+1][0][0,terms[idx][0].size]
					terms2 << terms[idx]
				elsif terms[idx][1] >= terms[idx+1][1] + 2
					terms2 << terms[idx]
				end
			end
			terms2 << terms[-1] if terms.size > 0

			terms2.collect {|t,n| t.reverse }
		end
		

		def extract_terms_sub(limit,str='',num=1,width=false)
			h = freq(str)
			flag = (h.size <= 4)

			result = []
			if limit > 0
				h.delete(str) if h.key?(str)
				h.to_a.delete_if { |k,v| v < 2 }.sort.each do |k,v|
					result.concat( extract_terms_sub(limit-1, k, v, flag) )
				end
			end

			if result.size == 0 && width
				return [[str.downcase,num]]
			end
			
			result
		end
		

		def freq(str)
			freq = Hash.new(0)

			if str.size == 0
				regexp = /([!-~])[!-~]*|([ァ-ヴ])[ァ-ヴー]*|([^ー\0])/i
				@buf.scan(regexp) { |ary| freq[ary[0] || ary[1] || ary[2]] += 1 }
			else
				regexp = /#{Regexp.quote(str)}[^\0]?/i
				@buf.scan(regexp) { |str| freq[str] += 1 }
			end
			
			freq
		end
	end

	class Trie
		def initialize(ary=nil)
			@root = {}
			if ary
				ary.each { |elm| self.add(elm) }
			end
		end
			
		def add(str)
			node = @root
			str.each_byte do |b|
				node[b] = {} unless node.key?(b)
				node = node[b]
			end
			node[:terminate] = true
		end

		def member?(str)
			node = @root
			str.each_byte do |b|
				return false unless node.key?(b)
				node = node[b]
			end

			node.key?(:terminate)
		end

		def members
			members_sub(@root)
		end

		def members_sub(node,str='')
			node.collect do |k,v|
				if k == :terminate
					str
				else
					members_sub(v,str+k.chr)
				end
			end.flatten
		end
		private :members_sub

		def split_into_terms(str,num=nil)
			result = []

			return result unless str

			while str.size > 0 && ( !num.kind_of?(Numeric) || result.size < num )
				prefix = longest_prefix_subword(str)
				if prefix
					result << prefix
					str = str[prefix.size..-1]
				else
					chr = /./m.match(str)[0]
					result << chr if num
					str = Regexp.last_match.post_match
				end
			end

			result
		end

		def longest_prefix_subword(str)
			node = @root
			result = nil
			idx = 0
			str.each_byte do |b|
				result = str[0,idx] if node.key?(:terminate)
				return result unless node.key?(b)
				node = node[b]
				idx += 1
			end
				
			result = str if node.key?(:terminate)
			result
		end

		def delete(str)
			node = @root
			ary = []
			str.each_byte do |b|
				return false unless node.key?(b)
				ary << [node,b]
				node = node[b]
			end

			return false unless node.key?(:terminate)
			ary << [node,:terminate]
				
			ary.reverse.each do |node,b|
				node.delete(b)
				break unless node.empty?
			end
				
			true
		end

	end

end

if $0 == __FILE__

	opt = {}
	while o = ARGV[0]
		case o
		when '-i'; opt[:i] = true;
		when '-m'; opt[:m] = true;
		when '-im'; opt[:i] = opt[:m] = true;
		when '--init'; opt[:init] = true;
		else break;
		end
		ARGV.shift
	end

	if opt[:init]

		dirname = ARGV[0]
		dic = Sixamo.init_dictionary(dirname)
		dic.save_dictionary

	elsif opt[:i]
		require 'readline'

		sixamo = Sixamo.new(ARGV[0])
		puts "簡易対話モード [exit,quit,空行で終了]"

		while (str = Readline.readline("> ", true))
			break if /^(exit|quit)?$/.match(str)

			if opt[:m]
				sixamo.memorize(str)
				res = sixamo.talk
			else
				res = sixamo.talk(str)
			end

			puts res
		end

	else

		sixamo = Sixamo.new(ARGV[0] || "data")
		str = ARGV[1]

		str = sixamo.talk(str)
		puts str

	end

end
