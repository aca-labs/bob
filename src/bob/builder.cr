require "docker"
require "inotify"

# Docker image builder.
class Bob::Builder
  private getter path : String
  private getter name : String
  private getter docker : Docker::Client

  def initialize(@path : String, image_name : String?, @docker = Docker.client)
    @name = image_name || Path.new(path).expand.basename
  end

  # Runs a build based on the current path contents.
  def build
    puts "building #{path}"
    puts docker.images.build path, t: name
  end

  # Start watching the path and automatically build when a new git commit is made, or when switching
  # to a new branch.
  def watch : Nil
    @watcher ||= Inotify.watch "#{path}/.git/logs/HEAD" do |event|
      next unless event.type == Inotify::Event::Type::MODIFY

      puts "git repo state modified"
    end
  end

  # Stop watching the build path.
  def unwatch : Nil
    watcher = @watcher # local assignment required for type resolution
    watcher.close unless watcher.nil?
  end
end
