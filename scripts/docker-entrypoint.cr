require "option_parser"

require "../src/bob/builder"

alias Project = NamedTuple(path: String, image_name: String)

# Get directories under a path
def repositories(base : String) : Array(Project)
  repository_paths = Dir.entries(base).select(&->File.directory?(String))
  # Construct projects
  repository_paths.map { |path| create_project(base, path) }
end

# Split path into image_name and path
def create_project(base, path) : Project
  {path: path, image_name: path.lstrip(base).lstrip('/')}
end

# Spawn a system level Bob process for a project
def spawn_bob(project : Project)
  Process.fork do
    builder = Bob::Builder.new(**project)

    puts "Bob is watching #{project[:path]}, building #{project[:image_name]}"
    builder.watch
    at_exit { builder.unwatch }

    sleep
  end
end

USAGE = "docker-entrypoint [REPOSITORIES_PATH]"

def main
  environment_repository = ENV["BOB_REPO_PATH"]?
  argument_repository = ARGV[0]?

  path = if argument_repository && ARGV.size == 1
           argument_repository
         elsif environment_repository
           environment_repository
         else
           puts USAGE
           puts
           puts "Expected $BOB_REPO_PATH or a repository path"
           puts
           exit 1
         end

  repositories(path).each &->spawn_bob(Project)
  sleep
end

main
