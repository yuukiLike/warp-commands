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
    [mode, YAML.load_file(File.join(ROOT, "pi/pi-#{mode}.yaml"))]
  end
  PRESET_PATH = File.join(ROOT, 'pi/settings.template.json')
  PRESET = JSON.parse(File.read(PRESET_PATH))
  DEFAULT_REF = PRESET.fetch('defaultModel')
  ASTRA_REF = 'openai/gpt-6.2-astra'

  def setup
    @temporary = File.realpath(Dir.mktmpdir('pi-settings-test-'))
    @home = File.join(@temporary, 'home')
    @repository = File.join(@home, 'codex/warp-commands')
    FileUtils.mkdir_p(@repository)
    FileUtils.cp_r(File.join(ROOT, 'pi'), @repository)
    @preset = File.join(@repository, 'pi/settings.template.json')
    @extension = File.join(@repository, 'pi/preset.mjs')
    @settings = {
      'defaultProvider' => DEFAULT_REF.split('/', 2).first,
      'defaultModel' => DEFAULT_REF.split('/', 2).last,
      'defaultThinkingLevel' => PRESET.fetch('defaultThinkingLevel'),
      'modelThinkingLevels' => PRESET.fetch('modelThinkingLevels'),
      'enabledModels' => [DEFAULT_REF, *PRESET.fetch('enabledModels')].uniq,
      'extensions' => [@extension]
    }
    @environment = { 'HOME' => @home, 'PATH' => ENV.fetch('PATH') }
  end

  def teardown
    FileUtils.remove_entry(@temporary)
  end

  def test_first_preset_start_uses_the_repository_without_seeding_user_files
    stub_command('pi')
    stdout, stderr, status = run_named_workflow('start', 'zsh')
    assert status.success?, stderr
    assert_equal ['--model', 'openai/gpt-6.2-sol', '--thinking', 'max', '--extension', @extension], stdout.lines.map(&:chomp)
    refute_includes PRESET.fetch('enabledModels'), DEFAULT_REF
    assert_equal PRESET, JSON.parse(File.read(@preset))
    refute File.exist?(File.join(@home, '.pi'))
    refute File.exist?(File.join(@home, '.config'))
  end

  def test_workflows_read_live_edits_from_a_custom_repository_path
    repo = File.join(@temporary, 'custom checkout')
    FileUtils.mv(@repository, repo)
    @environment['WARP_COMMANDS_DIR'] = repo
    preset = File.join(repo, 'pi/settings.template.json')
    extension = File.join(repo, 'pi/preset.mjs')
    legacy_preset = File.join(@home, '.config/warp-commands/pi/settings.template.json')
    FileUtils.mkdir_p(File.dirname(legacy_preset))
    File.write(legacy_preset, JSON.generate(PRESET))

    stub_command('pi')
    stdout, stderr, status = run_named_workflow('start', 'zsh')
    assert status.success?, stderr
    assert_equal ['--model', DEFAULT_REF, '--thinking', 'max', '--extension', extension], stdout.lines.map(&:chomp)

    custom = JSON.generate(defaultModel: 'different/next-model', defaultThinkingLevel: 'medium', enabledModels: ['different/other-model'])
    File.write(preset, custom)
    expected = {
      'defaultProvider' => 'different', 'defaultModel' => 'next-model', 'defaultThinkingLevel' => 'medium',
      'enabledModels' => ['different/next-model', 'different/other-model'], 'extensions' => [extension]
    }
    WORKFLOWS.each_key do |mode|
      directory = File.join(@home, mode)
      stdout, stderr, status = run_workflow(mode, 'zsh', 'PI_CODING_AGENT_DIR' => directory)
      assert status.success?, stdout + stderr
      assert_equal expected, JSON.parse(File.read(File.join(directory, 'settings.json')))
    end
    stdout, stderr, status = run_named_workflow('start', 'zsh')
    assert status.success?, stderr
    assert_equal ['--model', 'different/next-model', '--thinking', 'medium', '--extension', extension], stdout.lines.map(&:chomp)
    stdout, stderr, status = run_named_workflow('start', 'bash', model: 'different/explicit', thinking: 'low')
    assert status.success?, stderr
    assert_equal ['--model', 'different/explicit', '--thinking', 'low', '--extension', extension], stdout.lines.map(&:chomp)
    refute File.exist?(File.join(@home, '.pi'))
    assert_equal custom, File.read(preset)
    assert_equal PRESET, JSON.parse(File.read(legacy_preset))
  end

  def test_both_writers_are_idempotent_without_creating_a_template_copy
    %w[bash zsh].product(WORKFLOWS.keys).each do |shell, mode|
      directory = File.join(@temporary, "#{shell} #{mode}")
      environment = { 'PI_CODING_AGENT_DIR' => directory }
      2.times do
        stdout, stderr, status = run_workflow(mode, shell, environment)
        assert status.success?, stdout + stderr
        assert_equal @settings, JSON.parse(File.read(File.join(directory, 'settings.json')))
        assert_equal ['settings.json'], Dir.children(directory), 'must not create backups or other files'
      end
    end
    refute File.exist?(File.join(@home, '.config'))
  end

  def test_start_prefers_astras_default_over_the_global_level
    stub_command('pi')
    assert_equal 'max', PRESET.fetch('modelThinkingLevels').fetch(ASTRA_REF)
    File.write(@preset, JSON.generate(PRESET.merge('defaultThinkingLevel' => 'medium')))

    stdout, stderr, status = run_named_workflow('start', 'zsh', model: ASTRA_REF)
    assert status.success?, stderr
    assert_equal ['--model', ASTRA_REF, '--thinking', 'max', '--extension', @extension], stdout.lines.map(&:chomp)

    stdout, stderr, status = run_named_workflow('start', 'bash', model: ASTRA_REF, thinking: 'low')
    assert status.success?, stderr
    assert_equal ['--model', ASTRA_REF, '--thinking', 'low', '--extension', @extension], stdout.lines.map(&:chomp)
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
        assert_equal @settings, JSON.parse(File.read(file))
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
          DEFAULT_REF => 'low', ASTRA_REF => 'low', @settings.fetch('enabledModels').last => 'high', 'other/example' => 'medium'
        }
      }
      File.write(file, JSON.generate(original))
      expected = original.merge(@settings).merge(
        'enabledModels' => @settings.fetch('enabledModels') + ['other/example', 'openai/*:low', 'other/second'],
        'extensions' => ['local.ts', @extension],
        'modelThinkingLevels' => {
          DEFAULT_REF => 'max', ASTRA_REF => 'max', @settings.fetch('enabledModels').last => 'max', 'other/example' => 'medium'
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

      stdout, stderr, status = run_workflow(mode, shell, 'HOME' => home, 'WARP_COMMANDS_DIR' => @repository)
      assert status.success?, stdout + stderr
      assert_equal @settings, JSON.parse(File.read(File.join(directory, 'settings.json')))
      %w[auth.json models.json].each { |name| assert_equal "keep #{name}", File.read(File.join(directory, name)) }
      assert_equal '{"theme":"light"}', File.read(project)
      assert_equal %w[auth.json models.json settings.json], Dir.children(directory).sort
    end
  end

  def test_merge_rejects_malformed_json_and_wrong_field_types_without_writing
    invalid = [
      '{', 'null', '[]', 'true', '"text"',
      '{"enabledModels":null}', '{"enabledModels":"openai/*"}', '{"enabledModels":[1]}',
      '{"modelThinkingLevels":null}', '{"modelThinkingLevels":[]}', '{"modelThinkingLevels":"high"}',
      '{"extensions":null}', '{"extensions":"single.ts"}', '{"extensions":[1]}'
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

  def test_edit_opens_the_template_and_writers_expand_the_quoted_home_override
    stub_command('vi')
    environment = { 'PI_CODING_AGENT_DIR' => '~/custom agent' }
    file = File.join(@home, 'custom agent/settings.json')
    stdout, stderr, status = run_named_workflow('model-edit', 'zsh', environment: environment)
    assert status.success?, stderr
    assert_equal "#{@preset}\n", stdout
    refute File.exist?(File.dirname(file))
    WORKFLOWS.each_key do |mode|
      stdout, stderr, status = run_workflow(mode, 'bash', environment)
      assert status.success?, stdout + stderr
      assert_equal @settings, JSON.parse(File.read(file))
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
    variants = [
      '{', '{}', '{"defaultModel":"openai/x","enabledModels":["openai/*"]}',
      '{"defaultModel":"openai/x:low","enabledModels":[]}',
      JSON.generate(PRESET.merge('defaultThinkingLevel' => 'fast')),
      JSON.generate(PRESET.merge('modelThinkingLevels' => { ASTRA_REF => 'ultrafast' })),
      JSON.generate(PRESET.merge('serviceTiers' => { DEFAULT_REF => 'ultra fast' })),
      JSON.generate(PRESET.merge('serviceTiers' => { 'deepseek/some-model' => 'ultrafast' }))
    ]
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

  def test_service_tier_is_only_sent_for_the_configured_openai_responses_model
    source = <<~JS
      import assert from "node:assert/strict";
      import { pathToFileURL } from "node:url";
      const { default: register } = await import(pathToFileURL(process.argv[1]).href);
      let beforeRequest;
      register({ on(event, handler) {
        assert.equal(event, "before_provider_request");
        beforeRequest = handler;
      } });
      const model = { provider: "openai", id: "gpt-6.2-sol", api: "openai-responses" };
      const payload = { model: model.id, reasoning: { effort: "max" } };
      assert.deepEqual(beforeRequest({ payload }, { model }), { ...payload, service_tier: "ultrafast" });
      assert.equal(payload.service_tier, undefined);
      assert.equal(beforeRequest({ payload: { model: "gpt-6.1-sol" } }, { model: { ...model, id: "gpt-6.1-sol" } }), undefined);
      assert.equal(beforeRequest({ payload }, { model: { ...model, provider: "openai-codex" } }), undefined);
      assert.equal(beforeRequest({ payload }, { model: { ...model, api: "openai-completions" } }), undefined);
    JS
    stdout, stderr, status = Open3.capture3('node', '--input-type=module', '-e', source, @extension)
    assert status.success?, stdout + stderr
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
    expected_names = %w[start model-edit merge overwrite models refresh]
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
    workflow = YAML.load_file(File.join(ROOT, "pi/pi-#{name}.yaml"))
    command = workflow.fetch('command')
    workflow.fetch('arguments').each do |argument|
      key = argument.fetch('name')
      value = arguments.fetch(key.to_sym, argument.fetch('default_value'))
      command = command.gsub("{{#{key}}}") { value }
    end
    run_command(command, shell, environment)
  end

  def run_workflow(mode, shell, environment = {})
    run_command(WORKFLOWS.fetch(mode).fetch('command'), shell, environment)
  end

  def run_command(command, shell, environment)
    Open3.capture3(@environment.merge(environment), shell, '-f', '-c', command, chdir: @home, unsetenv_others: true)
  end
end
