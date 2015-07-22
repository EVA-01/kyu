require "kyu/version"
require 'user_config'
require 'pathname'
require 'mimemagic'

module Kyu
	class << self
		SUPPORTED = ['image']
		def init(where = ".")
			unless kyu?(where)
				kyu = config
				kyu['details.yaml']['committed'] = []
				kyu['details.yaml'].save
				puts "Created .kyu/"
				puts "Created .kyu/details.yaml"
			end
		end
		def delete(where = ".")
			kyu = directory where
			if kyu?(where)
				kyu.rmtree
				puts "Delete .kyu/"
			else
				error "Couldn't find .kyu"
			end
		end
		def setup(consumer_key, consumer_secret, oauth_token, oauth_token_secret)
			kyuc = UserConfig.new('.kyuc')
			kyuc['login.yaml']['consumer_key'] = consumer_key
			kyuc['login.yaml']['consumer_secret'] = consumer_secret
			kyuc['login.yaml']['oauth_token'] = oauth_token
			kyuc['login.yaml']['oauth_token_secret'] = oauth_token_secret
			kyuc.save
		end
		def client
			kyuc = UserConfig.new('.kyuc')
			if kyuc.exist? 'login.yaml'
				return Tumblr::Client.new({
					:consumer_key => kyuc['login.yaml']['consumer_key'],
					:consumer_secret => kyuc['login.yaml']['consumer_secret'],
					:oauth_token => kyuc['login.yaml']['oauth_token'],
					:oauth_token_secret => kyuc['login.yaml']['oauth_token_secret']
				})
			else
				raise "No login information for tumblr"
			end
		end
		def config(where = ".")
			return UserConfig.new('.kyu', :home => where)
		end
		def directory(where = ".")
			return Pathname.new(where) + ".kyu"
		end
		def kyu?(where = ".")
			return directory(where).directory?
		end
		def cleanupCommits
			kyu = config
			unc = []
			for file in kyu['details.yaml']['committed']
				unc << file unless File.exist?(file) and File.file?(file)
			end
			uncommit unc
		end
		##
		# Used to output a red string to the terminal.
		def red(what)
			return "\e[31m#{what}\e[0m"
		end
		##
		# Used to output a cyan string to the terminal.
		def cyan(what)
			return "\e[36m#{what}\e[0m"
		end
		##
		# Used to output a yellow string to the terminal.
		def yellow(what)
			return "\e[33m#{what}\e[0m"
		end
		##
		# Used to output a green string to the terminal.
		def green(what)
			return "\e[32m#{what}\e[0m"
		end
		def error(msg)
			puts "#{red("Error:")} #{msg}"
		end
		def warning(msg)
			puts "#{yellow("Warning:")} #{msg}"
		end
		def commit(what)
			unless kyu?
				init
			end
			kyu = config
			if what.class == Array
				for file in what
					if file and not kyu['details.yaml']['committed'].include?(file)
						if File.exists?(file) and File.file?(file)
							mime = MimeMagic.by_magic(File.open(file)) || MimeMagic.by_path(file)
							if mime != nil and SUPPORTED.include?(mime.mediatype)
								kyu['details.yaml']['committed'] << file
								puts "Committed #{file}"
							else
								warning("File \"#{file}\" is not valid.")
							end
						else
							warning("File \"#{file}\" is not valid.")
						end
					end
				end
				kyu['details.yaml'].save
			else
				commit [what]
			end
		end
		def uncommit(what)
			if kyu?
				kyu = config
				if what.class == Array
					copy = []
					for file in kyu['details.yaml']['committed']
						copy << file unless what.include?(file)
						puts "Uncommitted #{file}" if what.include?(file)
					end
					kyu['details.yaml']['committed'] = copy
					kyu['details.yaml'].save
				else
					uncommit [what]
				end
			end
		end
		def queue(options)
			tumblr = client
			options[:state] = 'queue'
			if kyu?
				cleanupCommits
				kyu = config
				for file in kyu['details.yaml']['committed']
					mime = MimeMagic.by_magic(File.open(file)) || MimeMagic.by_path(file)
					if mime != nil and SUPPORTED.include?(mime.mediatype)
						case mime.mediatype
						when 'image'
							req = tumblr.photo("#{client.info['user']['name']}.tumblr.com", ({:data => file}).merge(options))
						end
						if req.has_key? 'id' and not req.has_key? 'status'
							puts "#{green('OK:')} #{file}"
							uncommit file
						else
							puts "#{red("#{req['status']}:")} #{file}"
							for error in req['errors']
								puts "\t#{error}"
							end
						end
					else
						warning("File \"#{file}\" is not valid.")
					end
				end
			end
		end
	end
end