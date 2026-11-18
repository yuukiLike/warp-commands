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
  PRESET_PATH = File.join(ROOT, 'pi/settings.template.json')
  PRESET = JSON.parse(File.read(PRESET_PATH))
  DEFAULT_REF = PRESET.fetch('defaultModel')
  TEMPLATE = {
    'defaultProvider' => DEFAULT_REF.split('/', 2).first,
    'defaultModel' => DEFAULT_REF.split('/', 2).last,
    'defaultThinkingLevel' => 'max',
    'enabledModels' => [DEFAULT_REF, *PRESET.fetch('enabledModels')].uniq
  }.freeze

  def setup
    @temporary = Dir.mktmpdir('pi-settings-test-')
    @home = File.join(@temporary, 'home')
    @preset = File.join(@home, '.config/warp-commands/pi/settings.template.json')
    FileUtils.mkdir_p(@home)
    @environment = { 'HOME' => @home, 'PATH' => ENV.fetch('PATH') }
  end

  def teardown
    FileUtils.remove_entry(@temporary)
  end

  def test_generated_workflows_are_up_to_date
    assert_equal %w[defaultModel enabledModels], PRESET.keys.sort
    refute_includes PRESET.fetch('enabledModels'), DEFAULT_REF
    stdout, stderr, status = Open3.capture3('node', File.join(ROOT, 'pi/build-workflows.mjs'), '--check')
    assert status.success?, stdout + stderr
  end

  def test_generator_preserves_metadata_below_the_command_in_any_order
    pi_directory = File.join(@temporary, 'pi')
    FileUtils.cp_r(File.join(ROOT, 'pi'), pi_directory)
    workflow_path = File.join(pi_directory, 'pi-settings-merge.yaml')
    original = File.read(workflow_path)
    description = original.lines.find { |line| line.start_with?('description:') }
    comment = "# kept metadata comment\n"
    File.write(workflow_path, original.sub(description, comment) + description)
    File.write(File.join(pi_directory, 'settings.template.json'), JSON.generate(PRESET.merge('defaultModel' => 'openai/new-model')))

    stdout, stderr, status = Open3.capture3('node', File.join(pi_directory, 'build-workflows.mjs'))
    assert status.success?, stdout + stderr
    generated = YAML.load_file(workflow_path)
    assert_includes generated.delete('command'), 'openai/new-model'
    assert_equal YAML.safe_load(original).reject { |key, _| key == 'command' }, generated
    assert_includes File.read(workflow_path), comment
  end

  def test_first_preset_start_works_without_setup_and_seeds_the_local_template
    stub_command('pi')
    refute File.exist?(@preset)
    stdout, stderr, status = run_named_workflow('model-start', 'zsh', model: 'preset', thinking: 'max')
    assert status.success?, stderr
    assert_equal ['--model', DEFAULT_REF, '--thinking', 'max'], stdout.lines.map(&:chomp)
    assert_equal PRESET, JSON.parse(File.read(@preset))
    refute File.exist?(File.join(@home, '.pi'))
  end

  def test_workflows_read_the_current_preset_from_another_working_directory
    FileUtils.mkdir_p(File.dirname(@preset))
    custom = JSON.generate(defaultModel: 'different/next-model', enabledModels: ['different/other-model'])
    File.write(@preset, custom)
    expected = {
      'defaultProvider' => 'different', 'defaultModel' => 'next-model', 'defaultThinkingLevel' => 'max',
      'enabledModels' => ['different/next-model', 'different/other-model']
    }
    WORKFLOWS.each_key do |mode|
      directory = File.join(@home, mode)
      stdout, stderr, status = run_workflow(mode, 'zsh', 'PI_CODING_AGENT_DIR' => directory)
      assert status.success?, stdout + stderr
      assert_equal expected, JSON.parse(File.read(File.join(directory, 'settings.json')))
    end
    stub_command('pi')
    stdout, stderr, status = run_named_workflow('model-start', 'zsh', model: 'preset', thinking: 'max')
    assert status.success?, stderr
    assert_equal %w[--model different/next-model --thinking max], stdout.lines.map(&:chomp)
    stdout, stderr, status = run_named_workflow('model-start', 'bash', model: 'different/explicit', thinking: 'low')
    assert status.success?, stderr
    assert_equal %w[--model different/explicit --thinking low], stdout.lines.map(&:chomp)
    refute File.exist?(File.join(@home, '.pi'))
    assert_equal custom, File.read(@preset)
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

  def test_merge_gives_preset_exact_ids_precedence_without_discarding_other_patterns
    %w[bash zsh].each do |shell|
      directory = File.join(@temporary, shell)
      FileUtils.mkdir_p(directory)
      file = File.join(directory, 'settings.json')
      original = {
        'theme' => 'dark', 'packages' => ['example'], 'extensions' => ['local.ts'],
        'defaultTools' => ['read', 'bash'], 'lastChangelogVersion' => '0.87.1',
        'defaultProvider' => 'deepseek', 'defaultModel' => 'deepseek-v4-pro',
        'defaultThinkingLevel' => 'high',
        'enabledModels' => ['other/example', 'openai/*:low', "#{DEFAULT_REF}:low", 'other/second', 'other/example'],
        'modelThinkingLevels' => {
          DEFAULT_REF => 'low', TEMPLATE.fetch('enabledModels').last => 'high', 'other/example' => 'medium'
        }
      }
      File.write(file, JSON.generate(original))
      expected = original.merge(TEMPLATE).merge(
        'enabledModels' => TEMPLATE.fetch('enabledModels') + ['other/example', 'openai/*:low', 'other/second'],
        'modelThinkingLevels' => {
          DEFAULT_REF => 'max', TEMPLATE.fetch('enabledModels').last => 'max', 'other/example' => 'medium'
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

  def test_quoted_home_override_is_expanded_for_all_settings_commands
    stub_command('vi')
    environment = { 'PI_CODING_AGENT_DIR' => '~/custom agent' }
    file = File.join(@home, 'custom agent/settings.json')
    stdout, stderr, status = run_named_workflow('settings-edit', 'zsh', environment: environment)
    assert status.success?, stderr
    assert_equal "#{file}\n", stdout
    WORKFLOWS.each_key do |mode|
      stdout, stderr, status = run_workflow(mode, 'bash', environment)
      assert status.success?, stdout + stderr
      assert_equal TEMPLATE, JSON.parse(File.read(file))
    end
    refute File.exist?(File.join(@home, '~'))

    File.symlink('custom agent', File.join(@home, 'linked agent'))
    stdout, stderr, status = run_workflow('overwrite', 'bash', 'PI_CODING_AGENT_DIR' => '~/linked agent/')
    refute status.success?, stdout + stderr
    assert_includes stderr, '拒绝写入符号链接'
  end

  def test_invalid_preset_never_touches_current_settings
    directory = File.join(@home, '.pi/agent')
    FileUtils.mkdir_p(directory)
    file = File.join(directory, 'settings.json')
    original = '{"theme":"keep"}'
    File.write(file, original)
    FileUtils.mkdir_p(File.dirname(@preset))
    variants = ['{', '{}', '{"defaultModel":"openai/x","enabledModels":["openai/*"]}',
                '{"defaultModel":"openai/x:low","enabledModels":[]}']
    variants.each do |content|
      File.write(@preset, content)
      WORKFLOWS.each_key do |mode|
        stdout, stderr, status = run_workflow(mode, 'bash')
        refute status.success?, stdout + stderr
        assert_includes stderr, 'settings.template.json'
        assert_equal original, File.read(file)
        assert_equal ['settings.json'], Dir.children(directory)
      end
    end
  end

  def test_failed_replacement_preserves_old_file_and_cleans_up
    directory = File.join(@home, '.pi/agent')
    FileUtils.mkdir_p(directory)
    file = File.join(directory, 'settings.json')
    File.write(file, '{"theme":"keep"}')
    File.chmod(0o640, file)
    preload = File.join(@temporary, 'fail-rename.cjs')
    File.write(preload, <<~JS)
      require('node:fs').renameSync = () => { throw new Error('simulated rename failure'); };
      require('node:module').syncBuiltinESMExports();
    JS
    WORKFLOWS.each_key do |mode|
      stdout, stderr, status = run_workflow(mode, 'bash', 'NODE_OPTIONS' => "--require=#{preload}")
      refute status.success?, stdout + stderr
      assert_includes stderr, 'simulated rename failure'
      assert_equal '{"theme":"keep"}', File.read(file)
      assert_equal ['settings.json'], Dir.children(directory)
    end
    stdout, stderr, status = run_workflow('overwrite', 'bash')
    assert status.success?, stdout + stderr
    assert_equal 0o640, File.stat(file).mode & 0o777
  end

  def test_yaml_metadata_and_shell_syntax
    expected_names = %w[model-start model-search model-catalog-refresh settings-edit settings-merge settings-overwrite]
    assert_equal expected_names.sort, Dir[File.join(ROOT, 'pi/*.yaml')].map { |path| File.basename(path, '.yaml').delete_prefix('pi-') }.sort
    WORKFLOWS.each_value { |workflow| assert_equal [], workflow.fetch('arguments') }
    Dir[File.join(ROOT, 'pi/*.yaml')].each do |file|
      workflow = YAML.load_file(file)
      assert_equal File.basename(file, '.yaml').tr('-', ' '), workflow.fetch('name')
      workflow.fetch('shells').each do |shell|
        stdout, stderr, status = Open3.capture3(shell, '-n', stdin_data: workflow.fetch('command'))
        assert status.success?, "#{file} (#{shell}): #{stdout}#{stderr}"
      end
    end
  end

  def stub_command(name)
    bin = File.join(@temporary, 'bin')
    FileUtils.mkdir_p(bin)
    command = File.join(bin, name)
    File.write(command, "#!/bin/sh\nprintf '%s\\n' \"$@\"\n")
    File.chmod(0o700, command)
    @environment['PATH'] = "#{bin}:#{ENV.fetch('PATH')}"
  end

  def run_named_workflow(name, shell, environment: {}, **arguments)
    command = YAML.load_file(File.join(ROOT, "pi/pi-#{name}.yaml")).fetch('command')
    arguments.each { |key, value| command = command.gsub("{{#{key}}}", value) }
    run_command(command, shell, environment)
  end

  def run_workflow(mode, shell, environment = {})
    run_command(WORKFLOWS.fetch(mode).fetch('command'), shell, environment)
  end

  def run_command(command, shell, environment)
    Open3.capture3(@environment.merge(environment), shell, '-f', '-c', command, chdir: @home, unsetenv_others: true)
  end
end
