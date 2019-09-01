require "option_parser"
require "errno"
require "terminimal"
require "./version"
require "./builder"

class Bob::Cli
  VERSION = "bob #{Bob::VERSION}"
  ABOUT   = "CI/CD for local docker-based development"
  USAGE   = "Usage: bob [OPTION]... PATH"

  def self.run(options = ARGV)
    new(options).run
  end

  private getter options

  def initialize(@options : Array(String))
  end

  def run
    opts = OptionParser.new

    opts.banner = USAGE

    opts.on("-V", "--verion", "Show version information.") do
      puts VERSION
      exit
    end

    opts.on("-h", "--help", "Print this help message.") do
      puts VERSION
      puts ABOUT
      puts
      puts opts
      exit
    end

    name = nil
    opts.on("-t", "--tag", "The name to tag the built images with.") { |x| name = x }

    opts.invalid_option do |flag|
      Terminimal.exit_with_error "unkown option '#{flag}'", Errno::EINVAL
    end

    path = "."
    opts.unknown_args do |args|
      case
      when args.empty?
        Terminimal.exit_with_error "no PATH specified", Errno::EINVAL
      when !Dir.exists? args.first
        Terminimal.exit_with_error "specified PATH (#{path}) does not exist", Errno::EINVAL
      else
        path = args.first
      end
    end

    opts.parse options

    builder = Builder.new(path, name)

    builder.watch
    at_exit { builder.unwatch }

    # Let the builder do it's thing when required.
    sleep
  end
end
