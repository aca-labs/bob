require "colorize"
require "docker"
require "inotify"

# Docker image builder.
class Bob::Builder
  private getter path : String
  private getter name : String
  private getter docker : Docker::Client
  private property watcher : Inotify::Watcher?

  def initialize(@path : String, image_name : String?, @docker = Docker.client)
    @name = image_name || Path.new(path).expand.basename
  end

  # Runs a build based on the current path contents.
  def build
    puts "#{self}: action=build path=#{path} name=#{name}"
    docker.images.build path, t: name
  end

  # Start watching the path and automatically build when a new git commit is made, or when switching
  # to a new branch.
  def watch : Nil
    puts "#{self.inspect}: action=watch"
    @watcher ||= Inotify.watch "#{path}/.git/logs/HEAD" do |event|
      puts "#{self}: action=watch event=#{event}"
      next unless event.type == Inotify::Event::Type::MODIFY

      # FIXME: implement a file reader that tails this
      entry = `tail -n 1 #{event.path}`

      # Log entries appear for all actions (e.g. re-checking our of the current branch), only
      # progress on hash changes.
      old_hash, new_hash, _ = entry.split(" ")
      next unless new_hash != old_hash

      details = entry.split("\t")[1].chomp

      puts "#{self}: git repo change detected (#{details}), rebuilding"

      begin
        build
      rescue e : Docker::DockerException
        STDERR.puts "#{"error:".colorize.bright.red} #{e.message}"
      end
    end
  end

  # Stop watching the build path.
  def unwatch : Nil
    @watcher.try &.close
  end
end
