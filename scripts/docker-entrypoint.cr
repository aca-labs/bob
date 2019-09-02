require "option_parser"

require "../src/bob/builder"

alias Project = NamedTuple(path: String, image_name: String)

# Get directories under a path
def repositories(path : String) : Array(Project)
  Dir.entries(path)
    .select(&->File.directory?(String))
    .map(&->create_project(String))
end

def create_project(path) : Project
  {path: path, image_name: Path[path].basename}
end

# Spawn a system level Bob process for a project
def spawn_bob(project : Project)
  Process.fork do
    builder = Bob::Builder.new(**project)
    builder.watch
    at_exit { builder.unwatch }

    sleep
  end
end

USAGE = "docker-entrypoint REPOSITORIES_PATH"

def main
  unless (repositories_path = ARGV[0]?) && ARGV.size == 1
    puts USAGE
    puts
    puts "Expected a repository path"
    puts
    exit 1
  end

  repositories(repositories_path).each &->spawn_bob(Project)
  sleep
end

main
