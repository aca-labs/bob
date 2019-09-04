require "./bob/builder"

STDOUT.sync = true

# Run bob's entrypoint :)
entrypoint

alias Project = NamedTuple(path: String, image_name: String)

# Get directories under a path
def repositories(base : String) : Array(Project)
  base_path = Path[base]

  # Construct projects
  repository_paths(base_path).map { |path| project(base_path, path) }
end

# Generates repository paths by traversing directories
# Assumes directories containing a Dockerfile are repositories
def repository_paths(base : Path) : Array(Path)
  # Create paths from directory entries
  paths = Dir.entries(base.to_s)
    .map(&->Path.new(String))
    .map { |path| base.join(path) }

  # Assume cwd is a repository if it contains a Dockerfile
  return [base] if paths.any?(&.basename.starts_with?("Dockerfile"))

  # Grab directory paths while ignoring hidden files, '..' & '.'
  directories = paths.select { |path| File.directory?(path) && !path.basename.starts_with?(".") }
  directories.flat_map(&->repository_paths(Path))
end

# Split path into image_name and path
def project(base, absolute_path) : Project
  {
    path:       absolute_path.to_s,
    image_name: image_name(base, absolute_path),
  }
end

# Strip base from the repository
def image_name(base : Path, absolute_path : Path) : String
  absolute_path.to_s.lchop(base.to_s).lchop('/')
end

# Spawn a system level Bob process for a project
def spawn_bob(project : Project)
  puts "Starting Bob watching #{project[:path]}, building #{project[:image_name]}:latest"
  builder = Bob::Builder.new(**project)
  spawn { builder.watch }
  at_exit { builder.unwatch }
end

def entrypoint
  environment_repository = ENV["BOB_REPO_PATH"]?
  argument_repository = ARGV[1]?

  path = if argument_repository && ARGV.size == 2
           argument_repository
         elsif environment_repository
           environment_repository
         else
           puts "docker-entrypoint [REPOSITORIES_PATH]"
           puts
           puts "Expected $BOB_REPO_PATH or a repository path"
           puts
           exit 1
         end

  repositories(path).each &->spawn_bob(Project)
  sleep
end
