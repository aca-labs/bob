require "docker"

class Bob::Builder
  private getter path : String
  private getter name : String
  private getter docker : Docker::Client

  def initialize(@path : String, image_name : String?, @docker = Docker.client)
    @name = image_name || Path.new(path).expand.basename
  end

  def build
    puts "building #{path}"
    puts docker.images.build path, t: name
  end

  def watch
    build
  end
end
