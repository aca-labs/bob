require "option_parser"
require "errno"
require "terminimal"
require "./version"

class Bob::Cli
  VERSION = "bob #{Bob::VERSION}"
  ABOUT   = "CI/CD for local docker-based development"
  USAGE   = "Usage: bob [OPTION]... PATH..."

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

    opts.invalid_option do |flag|
      Terminimal.exit_with_error "unkown option '#{flag}'", Errno::EINVAL
    end

    paths = [] of String
    opts.unknown_args do |args|
      Terminimal.exit_with_error "no PATH specified", Errno::EINVAL if args.empty?
      paths = args
    end

    opts.parse options

    puts paths
  end
end
