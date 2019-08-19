module Bob
  VERSION = {{
    read_file("#{__DIR__}/../../shard.yml")
      .lines
      .map(&.strip)
      .find(&.starts_with? "version")
      .gsub(/version\: ?/, "")
  }}
end
