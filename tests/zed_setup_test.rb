# Run with: ruby tests/zed_setup_test.rb
# Runs the real workflow against temporary Zed configuration directories.
require 'fileutils'
require 'json'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

class ZedSetupTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  WORKFLOW = YAML.load_file(File.join(ROOT, 'setup/install-zed.yaml'))
  LABEL = 'Open HTML in Browser'
  CONTEXT = 'Editor && (extension == html || extension == htm)'

  def setup
    @temporary = Dir.mktmpdir('zed-html-test-')
    @config = File.join(@temporary, 'Zed config with spaces')
  end

  def teardown
    FileUtils.remove_entry(@temporary)
  end

  def run_workflow(shell = 'zsh', environment = {})
    Open3.capture3(
      { 'WARP_ZED_CONFIG_DIR' => @config }.merge(environment),
      shell, '-f', '-c', WORKFLOW.fetch('command'), chdir: @temporary
    )
  end

  def write_config(name, text)
    FileUtils.mkdir_p(@config)
    File.write(File.join(@config, name), text)
  end

  def read_config(name)
    JSON.parse(File.read(File.join(@config, name)))
  end

  def snapshot
    Dir.glob(File.join(@config, '**', '*'), File::FNM_DOTMATCH)
       .select { |file| File.file?(file) }
       .to_h { |file| [file, File.binread(file)] }
  end

  def assert_installed
    tasks = read_config('tasks.json').select { |task| task['label'] == LABEL }
    assert_equal 1, tasks.length
    task = tasks.first
    assert_equal 'open', task['command']
    assert_equal ['$ZED_FILE'], task['args']
    assert_equal 'current', task['save']
    assert_equal 'never', task['reveal']
    keymap = read_config('keymap.json')
    assert_equal CONTEXT, keymap.last['context']
    assert_equal ['task::Spawn', { 'task_name' => LABEL }], keymap.last.dig('bindings', 'cmd-ctrl-b')
    assert_equal 1, keymap.count { |group| group['context'] == CONTEXT }
  end

  def test_fresh_install_works_in_both_shells_and_is_idempotent
    %w[bash zsh].each do |shell|
      @config = File.join(@temporary, shell + ' config')
      stdout, stderr, status = run_workflow(shell)
      assert status.success?, stdout + stderr
      assert_installed
      assert_equal %w[keymap.json tasks.json], Dir.children(@config).sort
      before = snapshot
      stdout, stderr, status = run_workflow(shell)
      assert status.success?, stdout + stderr
      assert_includes stdout, '已是最新'
      assert_equal before, snapshot
    end
  end

  def test_jsonc_merge_preserves_other_settings_and_backs_up_exact_originals
    tasks = <<~'JSONC'
      // My tasks
      [
        {"label":"Other task","command":"echo \"https://example.com/a,]\"","env":{"ENABLED":true},},
        /* the managed task is replaced */
        {"label":"Open HTML in Browser","command":"old command",},
      ]
    JSONC
    keymap = <<~'JSONC'
      [
        {"context":"Workspace","bindings":{"cmd-b":null,"cmd-k cmd-p":"editor::CopyRelativePath"},},
        {"context":"Editor && (extension == html || extension == htm)",
         "bindings":{"cmd-l":"editor::SelectLine","cmd-ctrl-b":"old::Action"},
         "unbind":{"cmd-ctrl-b":"old::Action","cmd-alt-x":"other::Action"},},
        {"context":"Editor","bindings":{"cmd-ctrl-b":"other::Action"},},
      ]
    JSONC
    write_config('tasks.json', tasks)
    write_config('keymap.json', keymap)
    write_config('settings.json', '{"theme":"leave this alone"}')
    File.chmod(0o640, File.join(@config, 'tasks.json'))

    stdout, stderr, status = run_workflow
    assert status.success?, stdout + stderr
    assert_installed
    assert_equal 'echo "https://example.com/a,]"', read_config('tasks.json').first['command']
    assert_equal true, read_config('tasks.json').first.dig('env', 'ENABLED')
    groups = read_config('keymap.json')
    assert_nil groups.first.dig('bindings', 'cmd-b')
    assert_equal 'editor::CopyRelativePath', groups.first.dig('bindings', 'cmd-k cmd-p')
    assert_equal 'other::Action', groups[1].dig('bindings', 'cmd-ctrl-b')
    assert_equal 'editor::SelectLine', groups.last.dig('bindings', 'cmd-l')
    assert_equal({ 'cmd-alt-x' => 'other::Action' }, groups.last['unbind'])
    assert_equal '{"theme":"leave this alone"}', File.read(File.join(@config, 'settings.json'))
    assert_equal 0o640, File.stat(File.join(@config, 'tasks.json')).mode & 0o777
    backups = Dir.glob(File.join(@config, '.warp-html-*'))
    assert_equal 1, backups.length
    assert_equal tasks, File.read(File.join(backups.first, 'tasks.json.before'))
    assert_equal keymap, File.read(File.join(backups.first, 'keymap.json.before'))
    before = snapshot
    stdout, stderr, status = run_workflow
    assert status.success?, stdout + stderr
    assert_equal before, snapshot
  end

  def test_invalid_input_leaves_both_configs_untouched
    %w[tasks.json keymap.json].each do |name|
      invalid = ['[', '{}', 'null', '[null]', '[1]']
      invalid += ['[{"bindings":null}]', '[{"unbind":[]}]'] if name == 'keymap.json'
      invalid.each do |text|
        write_config('tasks.json', '[{"label":"keep","command":"echo keep"}]')
        write_config('keymap.json', '[{"bindings":{"cmd-b":null}}]')
        write_config(name, text)
        before = snapshot
        stdout, stderr, status = run_workflow
        refute status.success?, name + ': ' + stdout + stderr
        assert_equal before, snapshot
        assert_empty Dir.glob(File.join(@config, '.warp-html-*'))
      end
    end
  end

  def test_symlinked_files_and_config_directory_are_rejected
    outside = File.join(@temporary, 'outside.json')
    File.write(outside, '[]')
    %w[tasks.json keymap.json].each do |name|
      FileUtils.mkdir_p(@config)
      link = File.join(@config, name)
      File.symlink(outside, link)
      stdout, stderr, status = run_workflow
      refute status.success?, stdout + stderr
      assert_includes stderr, '符号链接'
      assert_equal '[]', File.read(outside)
      assert_equal [name], Dir.children(@config)
      File.unlink(link)
    end
    File.symlink(@config, File.join(@temporary, 'linked config'))
    stdout, stderr, status = run_workflow('zsh', 'WARP_ZED_CONFIG_DIR' => File.join(@temporary, 'linked config'))
    refute status.success?, stdout + stderr
    assert_includes stderr, '符号链接'
    assert_empty Dir.children(@config)
  end

  def test_second_write_failure_restores_first_file
    write_config('tasks.json', "// keep comments\n[]")
    write_config('keymap.json', '[]')
    before = snapshot
    preload = File.join(@temporary, 'fail-rename.cjs')
    File.write(preload, <<~'JS')
      const fs = require('node:fs');
      const rename = fs.renameSync;
      fs.renameSync = function (source, destination) {
        if (source.endsWith('keymap.json.next')) throw new Error('simulated write failure');
        return rename.apply(this, arguments);
      };
    JS
    stdout, stderr, status = run_workflow('zsh', 'NODE_OPTIONS' => '--require=' + preload)
    refute status.success?, stdout + stderr
    assert_includes stderr, 'simulated write failure'
    assert_equal before, snapshot
    assert_empty Dir.glob(File.join(@config, '.warp-html-*'))
  end

  def test_yaml_metadata_and_shell_syntax
    assert_equal 'setup zed', WORKFLOW.fetch('name')
    assert_equal [], WORKFLOW.fetch('arguments')
    WORKFLOW.fetch('shells').each do |shell|
      stdout, stderr, status = Open3.capture3(shell, '-n', stdin_data: WORKFLOW.fetch('command'))
      assert status.success?, stdout + stderr
    end
  end
end
