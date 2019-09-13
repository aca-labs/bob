require "colorize"
require "docker"
require "inotify"
require "uuid"

# Docker image builder.
class Bob::Builder
  private getter path : String
  private getter name : String
  private getter docker : Docker::Client
  private getter docker_api : Docker::Api::ApiClient
  private property watcher : Inotify::Watcher?

  def initialize(
    @path : String,
    image_name : String? = nil,
    @docker = Docker.client,
    @docker_api = Docker.api_client
  )
    @name = image_name || Path.new(path).expand.basename
  end

  # Runs a build based on the current path contents.
  def build
    puts "#{self}: action=build path=#{path} name=#{name}"
    docker.images.build path, t: name
  end

  # Recreate a container, using the current image.
  #
  # 1. Spawns a new container with the same...
  #   - network
  #   - port mappings
  #   - environment
  #   - labels
  #   - entrypoint
  #   - working directory
  #   - volumes (using volumes_from)
  # 1. Stops old container
  # 1. Starts the new container
  # 1. Removes the old container
  # 1. Renames the new container to old container name
  def recreate_container(container : Docker::Container)
    puts "#{self}: action=recreate_container container_name=#{container.name}"

    # Networks
    networks = container.attrs.network_settings.networks.keys
    puts "Warning: Multiple networks #{networks}" if networks.size > 1
    primary_network = networks.first

    # Port mappingss
    ports = container.attrs.host_config.port_bindings

    # Environment
    environment = container.attrs.config.env

    # Labels
    labels = container.attrs.config.labels

    # Entrypoint / Cmd
    command = container.attrs.config.cmd

    # Working directory
    working_dir = container.attrs.config.working_dir

    temporary_name = "#{container.name}-#{Random.new.hex(4)}"
    new_container = docker.containers.create(
      name: temporary_name,
      image: name,
      labels: labels,
      volumes_from: [container.id],
      network: primary_network,
      ports: ports,
      working_dir: working_dir,
      environment: environment,
      entrypoint: command,
    )

    # Stop the existing container
    container.stop

    # Start the temporary container
    new_container.start

    # Remove the existing container
    container.remove(v: false, force: true)

    # Rename the temporary container to the original container
    new_container.rename(container.name)
  end

  # Inspect existing containers for an image
  def existing_containers : Array(Docker::Container)
    docker.containers.list filters: {:ancestor => name}
  end

  def relaunch_containers
    existing_containers.each &->recreate_container(Docker::Container)
  end

  # Start watching the path and automatically build an image and relaunch containers
  # when a new git commit is made, or when switching to a new branch.
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
        relaunch_containers
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
