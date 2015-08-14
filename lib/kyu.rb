require "kyu/version"
require 'user_config'
require 'pathname'
require 'mimemagic'

module Kyu
	SUPPORTED = ['image']
	COMMITTED = 'added.yaml'
	LOGIN = 'login.yaml'
	class << self
		def init
			kyuc = UserConfig.new('.kyuc')
			kyuc[LOGIN].save unless kyuc.exist? LOGIN
			kyuc[COMMITTED]['committed'] = [] unless kyuc.exist? COMMITTED
			kyuc[COMMITTED].save unless kyuc.exist? COMMITTED
		end
		def setup(consumer_key, consumer_secret, oauth_token, oauth_token_secret)
			init unless kyu?
			kyuc = UserConfig.new('.kyuc')
			kyuc[LOGIN]['consumer_key'] = consumer_key
			kyuc[LOGIN]['consumer_secret'] = consumer_secret
			kyuc[LOGIN]['oauth_token'] = oauth_token
			kyuc[LOGIN]['oauth_token_secret'] = oauth_token_secret
			kyuc[LOGIN].save
		end
		def client
			kyuc = UserConfig.new('.kyuc')
			if kyuc.exist? LOGIN
				return Tumblr::Client.new({
					:consumer_key => kyuc[LOGIN]['consumer_key'],
					:consumer_secret => kyuc[LOGIN]['consumer_secret'],
					:oauth_token => kyuc[LOGIN]['oauth_token'],
					:oauth_token_secret => kyuc[LOGIN]['oauth_token_secret']
				})
			else
				raise "No login information for tumblr"
			end
		end
		def config
			return UserConfig.new('.kyuc')
		end
		def kyu?
			kyuc = config
			return (kyuc.exist?(LOGIN) and kyuc.exist?(COMMITTED))
		end
		def cleanupCommits(options = {:verbose => false})
			kyuc = config
			unc = []
			for file in kyuc[COMMITTED]['committed']
				unc << file unless File.exist?(file) and File.file?(file)
			end
			remove unc, options
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
		def add(what, options = {:verbose => false})
			init unless kyu?
			kyuc = config
			if what.class == Array
				for file in what
					if file and not kyuc[COMMITTED]['committed'].include?(file)
						if File.exists?(file) and File.file?(file)
							mime = MimeMagic.by_magic(File.open(file)) || MimeMagic.by_path(file)
							if mime != nil and SUPPORTED.include?(mime.mediatype)
								kyuc[COMMITTED]['committed'] << file
								puts "Added #{file}" if options[:verbose]
							else
								warning("File \"#{file}\" is not valid.") if options[:verbose]
							end
						else
							warning("File \"#{file}\" is not valid.") if options[:verbose]
						end
					end
				end
				kyuc[COMMITTED].save
			else
				add [what], options
			end
		end
		def list
			if kyu?
				kyuc = config
				return kyuc[COMMITTED]['committed']
			else
				return []
			end
		end
		def clean
			kyuc = config
			kyuc[COMMITTED]['committed'] = []
			kyuc[COMMITTED].save
		end
		def remove(what, options = {:verbose => false})
			if kyu?
				kyuc = config
				if what.class == Array
					copy = []
					for file in kyuc[COMMITTED]['committed']
						copy << file unless what.include?(file)
						puts "Removed #{file}" if what.include?(file) and options[:verbose]
					end
					kyuc[COMMITTED]['committed'] = copy
					kyuc[COMMITTED].save
				else
					remove [what], options
				end
			end
		end
		def queue(options)
			tumblr = client
			options[:state] = 'queue'
			passed = options.clone
			passed.tap { |hs| hs.delete(:verbose) }
			if kyu?
				cleanupCommits
				kyu = config
				for file in kyu[COMMITTED]['committed']
					mime = MimeMagic.by_magic(File.open(file)) || MimeMagic.by_path(file)
					if mime != nil and SUPPORTED.include?(mime.mediatype)
						case mime.mediatype
							when 'image'
								req = tumblr.photo("#{client.info['user']['name']}.tumblr.com", ({:data => file}).merge(passed))
						end
						if req.has_key? 'id' and not req.has_key? 'status'
							puts "#{green('OK:')} #{file}" if options[:verbose]
							remove file
						else
							if options[:verbose]
								puts "#{red("#{req['status']}:")} #{file}"
								for error in req['errors']
									puts "\t#{error}"
								end
							end
						end
					else
						warning("File \"#{file}\" is not valid.") if options[:verbose]
					end
				end
			end
		end
	end
end