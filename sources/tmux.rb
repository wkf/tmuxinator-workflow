require 'yaml'
require './alfred'

module Tmux
  BINARY = '/usr/local/bin/tmux/'.freeze

  def self.invoke(command, format = '')
    if format.empty?
      invoke_raw command
    elsif format.is_a?(String)
      invoke_raw command, "-F \"\#{#{format}}\""
    elsif format.is_a?(Array)
      invoke_raw(
        command,
        "-F \"#{format.map {|f| "\#{#{f}}"} .join(' ')}\""
      ).map { |r| r.split(' ') }
    elsif format.is_a?(Hash)
      invoke_raw(
        command,
        "-F \"#{format.map {|k, f| "\#{#{f}}"} .join(' ')}\""
      ).map { |r| Hash[format.keys.zip r.split(' ')] }
    end
  end

  def self.clients
    invoke 'list-clients', 'client_tty'
  end

  def self.sessions
    invoke 'list-sessions', 'session_name'
  end

  private

  def self.invoke_raw(command, format = '')
    `#{BINARY} #{command} #{format}`.split("\n")
  end
end

class Tmux::Session < Alfred::Source
  def candidates
    Tmux.sessions.map do |name|
      {:title => name, :subtitle => "Focus this session"}
    end
  end

  def focus(name)
    Tmux.invoke "\
      switch-client -c #{Tmux.clients.first} -t '#{name}'"
  end

  alias :default :focus
end

class Tmux::SessionCreate < Alfred::Source
  def candidates(seed = '')
    [
      :arg => seed,
      :subtitle => 'Create this session',
      :title => "Create session #{seed}"
    ]
  end

  def filter(seed)
    candidates(seed) if Tmux.sessions.grep(seed).empty?
  end

  def create(name, path = nil)
    template = YAML::load_file 'default_template.yml'

    template['name'] = name
    template['root'] = path if !path.nil?

    File.open(ENV['HOME'] + "/.tmuxinator/#{name}.yml", 'w') do |f|
      f.write template.to_yaml
    end

    Tmux.invoke "new-session -d 'mux s #{name}'"
    Tmux.invoke "\
      switch-client -c #{Tmux.clients.first} -t '#{name}'"
  end

  def create_from_path(path)
    create File.basename(path), path
  end

  alias :default :create
end

Alfred.register_source 'tmux/session', Tmux::Session
Alfred.register_source 'tmux/session_create', Tmux::SessionCreate
