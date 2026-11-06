# Run with: ruby tests/pi_settings_test.rb
# Standard library only. All configuration stays in temporary directories;
# no Pi process, real credentials, or network calls are used.
require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

class PiSettingsTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  WORKFLOWS = %w[overwrite merge].to_h do |mode|
    [mode, YAML.load_file(File.join(ROOT, "pi/pi-settings-#{mode}.yaml"))]
  end
  TEMPLATE = JSON.parse(File.read(File.join(ROOT, 'pi/settings.json')))

  def setup
    @temporary = Dir.mktmpdir('pi-settings-test-')
    @home = File.join(@temporary, 'home')
    FileUtils.mkdir_p(@home)
    @environment = { 'HOME' => @home, 'PI_CODING_AGENT_DIR' => nil }
  end

  def teardown
    FileUtils.remove_entry(@temporary)
  end

  def test_template_and_readme_match_the_agreed_defaults
    assert_equal 'openai', TEMPLATE.fetch('defaultProvider')
    assert_equal 'gpt-6.1-sol', TEMPLATE.fetch('defaultModel')
    assert_equal 'max', TEMPLATE.fetch('defaultThinkingLevel')
    assert_equal %w[deepseek openai], TEMPLATE.fetch('enabledModels').map { |id| id.split('/').first }.uniq.sort
    readme_json = File.read(File.join(ROOT, 'pi/README.md')).scan(/```json\n(.*?)\n```/m)
    assert_equal [TEMPLATE], readme_json.map { |match| JSON.parse(match.first) }
  end

  def test_both_workflows_create_the_template_and_are_idempotent
    %w[bash zsh].product(WORKFLOWS.keys).each do |shell, mode|
      directory = File.join(@temporary, "#{shell} #{mode}")
      environment = { 'PI_CODING_AGENT_DIR' => directory }
      2.times do
        stdout, stderr, status = run_workflow(mode, shell, environment)
        assert status.success?, stdout + stderr
        assert_equal TEMPLATE, JSON.parse(File.read(File.join(directory, 'settings.json')))
        assert_equal ['settings.json'], Dir.children(directory), 'must not create backups or other files'
      end
    end
  end

  def test_overwrite_replaces_old_settings_without_backup
    %w[bash zsh].each do |shell|
      directory = File.join(@temporary, shell)
      FileUtils.mkdir_p(directory)
      file = File.join(directory, 'settings.json')
      ['{"theme":"dark","packages":["example"]}', 'invalid old JSON'].each do |original|
        File.write(file, original)
        stdout, stderr, status = run_workflow('overwrite', shell, 'PI_CODING_AGENT_DIR' => directory)
        assert status.success?, stdout + stderr
        assert_equal TEMPLATE, JSON.parse(File.read(file))
        assert_equal ['settings.json'], Dir.children(directory)
      end
    end
  end

  def test_merge_preserves_other_settings_and_appends_models_without_duplicates
    %w[bash zsh].each do |shell|
      directory = File.join(@temporary, shell)
      FileUtils.mkdir_p(directory)
      file = File.join(directory, 'settings.json')
      original = {
        'theme' => 'dark', 'packages' => ['example'], 'extensions' => ['local.ts'],
        'defaultTools' => ['read', 'bash'], 'lastChangelogVersion' => '0.87.1',
        'defaultProvider' => 'deepseek', 'defaultModel' => 'deepseek-v4-pro',
        'defaultThinkingLevel' => 'high',
        'enabledModels' => ['other/example', 'openai/gpt-6.1-sol', 'other/example'],
        'modelThinkingLevels' => {
          'openai/gpt-6.1-sol' => 'low', 'deepseek/deepseek-v4-pro' => 'high',
          'other/example' => 'medium'
        }
      }
      File.write(file, JSON.generate(original))
      expected = original.merge(TEMPLATE).merge(
        'enabledModels' => (original.fetch('enabledModels') + TEMPLATE.fetch('enabledModels')).uniq,
        'modelThinkingLevels' => {
          'openai/gpt-6.1-sol' => 'max', 'deepseek/deepseek-v4-pro' => 'max',
          'other/example' => 'medium'
        }
      )
      2.times do
        stdout, stderr, status = run_workflow('merge', shell, 'PI_CODING_AGENT_DIR' => directory)
        assert status.success?, stdout + stderr
        assert_equal expected, JSON.parse(File.read(file))
        assert_equal ['settings.json'], Dir.children(directory)
      end
    end
  end

  def test_default_directory_and_credentials_are_untouched
    %w[bash zsh].product(WORKFLOWS.keys).each do |shell, mode|
      home = File.join(@temporary, "#{shell} #{mode}")
      directory = File.join(home, '.pi/agent')
      FileUtils.mkdir_p(directory)
      %w[auth.json models.json].each { |name| File.write(File.join(directory, name), "keep #{name}") }
      project = File.join(home, '.pi/settings.json')
      File.write(project, '{"theme":"light"}')

      stdout, stderr, status = run_workflow(mode, shell, 'HOME' => home)
      assert status.success?, stdout + stderr
      assert_equal TEMPLATE, JSON.parse(File.read(File.join(directory, 'settings.json')))
      %w[auth.json models.json].each { |name| assert_equal "keep #{name}", File.read(File.join(directory, name)) }
      assert_equal '{"theme":"light"}', File.read(project)
      assert_equal %w[auth.json models.json settings.json], Dir.children(directory).sort
    end
  end

  def test_merge_rejects_malformed_json_and_wrong_field_types_without_writing
    invalid = [
      '{', 'null', '[]', 'true', '"text"',
      '{"enabledModels":null}', '{"enabledModels":"openai/*"}', '{"enabledModels":[1]}',
      '{"modelThinkingLevels":null}', '{"modelThinkingLevels":[]}', '{"modelThinkingLevels":"high"}'
    ]
    %w[bash zsh].each do |shell|
      directory = File.join(@temporary, shell)
      FileUtils.mkdir_p(directory)
      file = File.join(directory, 'settings.json')
      invalid.each do |original|
        File.write(file, original)
        stdout, stderr, status = run_workflow('merge', shell, 'PI_CODING_AGENT_DIR' => directory)
        refute status.success?, stdout + stderr
        assert_equal original, File.read(file)
        assert_equal ['settings.json'], Dir.children(directory)
        assert_empty stdout
      end
    end
  end

  def test_symlinked_settings_and_agent_directory_are_rejected
    %w[bash zsh].product(WORKFLOWS.keys, %w[file directory dangling]).each do |shell, mode, kind|
      real = File.join(@temporary, "real #{shell} #{mode} #{kind}")
      directory = File.join(@temporary, "agent #{shell} #{mode} #{kind}")
      if kind == 'directory'
        FileUtils.mkdir_p(real)
        File.write(File.join(real, 'settings.json'), 'keep')
        File.symlink(real, directory)
      else
        FileUtils.mkdir_p(directory)
        File.write(real, 'keep') unless kind == 'dangling'
        File.symlink(real, File.join(directory, 'settings.json'))
      end
      stdout, stderr, status = run_workflow(mode, shell, 'PI_CODING_AGENT_DIR' => directory)
      refute status.success?, stdout + stderr
      assert_includes stderr, '拒绝写入符号链接'
      if kind == 'dangling'
        refute File.exist?(real)
      else
        assert_equal 'keep', File.read(kind == 'file' ? real : File.join(real, 'settings.json'))
      end
    end
  end

  def test_yaml_metadata_and_shell_syntax
    WORKFLOWS.each do |mode, workflow|
      assert_equal "pi settings #{mode}", workflow.fetch('name')
      assert_equal [], workflow.fetch('arguments')
    end
    Dir[File.join(ROOT, 'pi/*.yaml')].each do |file|
      workflow = YAML.load_file(file)
      workflow.fetch('shells').each do |shell|
        stdout, stderr, status = Open3.capture3(shell, '-n', stdin_data: workflow.fetch('command'))
        assert status.success?, "#{file} (#{shell}): #{stdout}#{stderr}"
      end
    end
  end

  def run_workflow(mode, shell, environment = {})
    Open3.capture3(@environment.merge(environment), shell, '-f', '-c', WORKFLOWS.fetch(mode).fetch('command'), chdir: @home)
  end
end
