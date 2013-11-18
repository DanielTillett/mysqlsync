#!/usr/bin/env ruby

require 'rubygems'
require 'commander'
require 'commander/import'
require 'octokit'
require 'psych'
require 'terminal-notifier'

$client = nil

# @todo: Evitar mostrar notificaciones ya enviadas.

program :name, 'GitHub Alert Notifications Tool'
program :version, '1.0.0'
program :description, 'Notify all schema change on projects building in ruby.'
program :help, 'Author', 'Nicola Strappazzon <nicola51980@gmail.com>'

command :alert do |c|
  c.description = 'Install audit table'
  c.syntax = "ghcant alert --user root --pass admin --rgex 'db(.*)' --title 'GitHub - Wuaki.tv' --subtitle 'Changes on DataBase'"
  c.option '--user STRING', String, 'User for your account in GitHub'
  c.option '--pass STRING', String, 'Password for your account in GitHub'
  c.option '--rgex STRING', String, 'Regular expressions to find file name'
  c.option '--title STRING', String, 'Title in message'
  c.option '--subtitle STRING', String, 'Subtitle in message'
  c.action do |args, options|
    connect(options.user, options.pass)
    alerts(options.rgex, options.title, options.subtitle)
  end
end

def connect(user, pass)
  begin
    $client = Octokit::Client.new(:login => user, :password => pass)
    $client.authorizations
  rescue
    puts "Invalid user name or passowrd."
    exit 1
  end
end


def alerts(rgex, title, subtitle)
  files = []
  news  = []

  commits = $client.list_commits("wuakitv/wuaki_common", "master")
  commits.map do | commits_item |
    commits_files = $client.commit("wuakitv/wuaki_common", commits_item.sha).files

    commits_files.map do | files_item |
      if ( files_item.filename =~ /#{Regexp.quote(rgex)}/)
        files << files_item.filename
      end
    end
    if !files.empty?
      news << [:sha => commits_item.sha, :files => files.join(', ')]
      files.clear
    end
  end

  news.map{|sha|sha.first}.uniq.each do | commit |
     TerminalNotifier.notify(commit[:files], :title    => title,
                                             :subtitle => subtitle,
                                             :open     => "https://github.com/wuakitv/wuaki_common/commit/#{commit[:sha]}",
                                             :group    => "#{commit[:sha]}")
  end
end