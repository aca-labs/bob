require "./bob/cli"

RUNNING_SPECS = PROGRAM_NAME.ends_with? "crystal-run-spec.tmp"

Crystal.main &->Bob::Cli.run unless RUNNING_SPECS
