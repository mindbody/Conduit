require 'yaml'

touched_files = git.modified_files + git.added_files

has_source_changes = !touched_files.grep(/Source/).empty?
has_test_changes = !touched_files.grep(/Tests/).empty?

if has_source_changes && !touched_files.include?('CHANGELOG.md')
	warn("Source files were modified -- don't forget to update the CHANGELOG if there are code changes.\nYou can find examples within the [CHANGELOG.md](https://github.com/mindbody/Conduit/blob/master/CHANGELOG.md")
end

if git.lines_of_code > 50 && has_source_changes && !has_test_changes
	warn("These changes may need unit tests.")
end

swiftlint.config_file = File.join(Dir.pwd, '.swiftlint.yml')
swiftlint.lint_files