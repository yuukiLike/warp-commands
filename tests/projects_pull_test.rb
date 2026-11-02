# Run with: ruby tests/projects_pull_test.rb
# Uses only macOS's Ruby standard library, Git, and Zsh. All repositories and
# shell configuration live in a temporary directory; no network is used.
require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

class ProjectsPullTest < Minitest::Test
  ROOT = File.expand_path('..', __dir__)
  INSTALL = YAML.load_file(File.join(ROOT, 'setup/install-projects-pull.yaml')).fetch('command')
  WORKFLOW = YAML.load_file(File.join(ROOT, 'mac/projects-pull.yaml')).fetch('command')

  def setup
    @temporary = Dir.mktmpdir('projects-pull-test-')
    @home = File.join(@temporary, 'home')
    @projects = File.join(@home, 'codex')
    @remote = File.join(@temporary, 'remote')
    FileUtils.mkdir_p(@projects)
    @environment = {
      'HOME' => @home, 'ZDOTDIR' => @home,
      'GIT_CONFIG_NOSYSTEM' => '1', 'GIT_CONFIG_GLOBAL' => '/dev/null',
      'GIT_CONFIG_COUNT' => '0', 'GIT_DIR' => nil, 'GIT_COMMON_DIR' => nil,
      'GIT_WORK_TREE' => nil, 'GIT_INDEX_FILE' => nil,
      'GIT_AUTHOR_NAME' => 'Test', 'GIT_AUTHOR_EMAIL' => 'test@example.invalid',
      'GIT_COMMITTER_NAME' => 'Test', 'GIT_COMMITTER_EMAIL' => 'test@example.invalid',
      'GIT_TERMINAL_PROMPT' => '0'
    }
    git('init', '-b', 'main', @remote)
    File.write(File.join(@remote, 'file.txt'), "initial\n")
    git('-C', @remote, 'add', 'file.txt')
    git('-C', @remote, 'commit', '-m', 'initial')
    @initial = revision(@remote, 'main')
    stdout, stderr, result = shell(INSTALL)
    assert result.success?, stdout + stderr
  end

  def teardown
    FileUtils.remove_entry(@temporary) if @temporary && File.exist?(@temporary)
  end

  def test_updates_multiple_projects_and_preserves_dirty_feature_branch
    feature = clone_project('feature project')
    main = clone_project('main project')
    git('-C', feature, 'switch', '-c', 'feature/demo')
    File.write(File.join(feature, 'staged.txt'), "staged\n")
    git('-C', feature, 'add', 'staged.txt')
    File.write(File.join(feature, 'file.txt'), "unstaged\n")
    File.write(File.join(feature, 'untracked.txt'), "untracked\n")
    before = working_state(feature)
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_includes stdout, '更新 2'
    assert_equal target, revision(feature, 'main')
    assert_equal target, revision(main, 'main')
    assert_equal before, working_state(feature)
    assert_equal "untracked\n", File.read(File.join(feature, 'untracked.txt'))
    assert_equal "remote update\n", File.read(File.join(main, 'file.txt'))
    assert_equal 'main', git('-C', main, 'branch', '--show-current').strip
  end

  def test_dirty_main_is_skipped_even_if_config_hides_untracked_files
    repo = clone_project('dirty main')
    git('-C', repo, 'config', 'status.showUntrackedFiles', 'no')
    File.write(File.join(repo, 'untracked.txt'), "keep\n")
    advance_remote

    stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'main has uncommitted changes'
    assert_equal @initial, revision(repo, 'main')
    assert_equal "keep\n", File.read(File.join(repo, 'untracked.txt'))
  end

  def test_main_with_staged_changes_is_skipped
    repo = clone_project('staged main')
    File.write(File.join(repo, 'file.txt'), "local edit\n")
    git('-C', repo, 'add', 'file.txt')
    before = working_state(repo)
    advance_remote

    _stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_equal @initial, revision(repo, 'main')
    assert_equal before, working_state(repo)
  end

  def test_ahead_main_is_preserved
    repo = clone_project('ahead')
    git('-C', repo, 'commit', '--allow-empty', '-m', 'local commit')
    local_main = revision(repo, 'main')
    git('-C', repo, 'switch', '-c', 'feature')

    stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'main has local commits; kept'
    assert_equal local_main, revision(repo, 'main')
    assert_equal 'feature', git('-C', repo, 'branch', '--show-current').strip
  end

  def test_diverged_main_is_preserved_and_later_projects_continue
    divergent = clone_project('a-divergent')
    healthy = clone_project('z-healthy')
    git('-C', divergent, 'commit', '--allow-empty', '-m', 'local commit')
    local_main = revision(divergent, 'main')
    target = advance_remote

    stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, '跳过 1'
    assert_equal local_main, revision(divergent, 'main')
    assert_equal target, revision(healthy, 'main')
  end

  def test_creates_missing_main_without_switching_branches
    repo = clone_project('no local main')
    git('-C', repo, 'switch', '-c', 'feature')
    git('-C', repo, 'branch', '-D', 'main')
    before = working_state(repo)
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'main')
    assert_equal before, working_state(repo)
  end

  def test_unchanged_main_reports_up_to_date
    repo = clone_project('unchanged')
    stdout, stderr, result = pull
    assert result.success?, stdout + stderr
    assert_includes stdout, '已是最新 1'
    assert_equal @initial, revision(repo, 'main')
  end

  def test_detached_head_and_its_changes_are_preserved
    repo = clone_project('detached')
    git('-C', repo, 'switch', '--detach')
    File.write(File.join(repo, 'file.txt'), "detached work\n")
    before = working_state(repo)
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_includes stdout, '(detached)'
    assert_equal target, revision(repo, 'main')
    assert_equal before, working_state(repo)
  end

  def test_main_fast_forward_overrides_merge_and_pull_preferences
    repo = clone_project('merge preferences')
    git('-C', repo, 'config', 'pull.rebase', 'true')
    git('-C', repo, 'config', 'merge.autoStash', 'true')
    git('-C', repo, 'config', 'branch.main.mergeOptions', '--no-ff --squash')
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'HEAD')
    assert_equal "remote update\n", File.read(File.join(repo, 'file.txt'))
    assert_equal "2\n", git('-C', repo, 'rev-list', '--count', 'main')
  end

  def test_unborn_main_is_initialized_without_changing_its_name
    repo = File.join(@projects, 'unborn main')
    git('init', '-b', 'main', repo)
    git('-C', repo, 'remote', 'add', 'origin', @remote)
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'HEAD')
    assert_equal 'main', git('-C', repo, 'branch', '--show-current').strip
    assert_equal "remote update\n", File.read(File.join(repo, 'file.txt'))
  end

  def test_missing_origin_is_skipped
    repo = clone_project('no origin')
    git('-C', repo, 'remote', 'remove', 'origin')
    stdout, _stderr, result = pull
    assert_equal 1, result.exitstatus
    assert_includes stdout, 'no origin remote'
    assert_equal @initial, revision(repo, 'main')
  end

  def test_fetch_failure_does_not_stop_later_projects
    broken = clone_project('a-broken')
    healthy = clone_project('z-healthy')
    git('-C', broken, 'remote', 'set-url', 'origin', File.join(@temporary, 'missing remote'))
    target = advance_remote

    stdout, stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, '失败 1'
    refute_empty stderr
    assert_equal @initial, revision(broken, 'main')
    assert_equal target, revision(healthy, 'main')
  end

  def test_remote_without_main_fails_without_changing_local_main
    repo = clone_project('no remote main')
    git('-C', @remote, 'branch', '-m', 'main', 'master')
    stdout, stderr, result = pull
    assert_equal 1, result.exitstatus
    assert_includes stdout, 'failed: fetch origin/main'
    refute_empty stderr
    assert_equal @initial, revision(repo, 'main')
  end

  def test_main_in_another_worktree_is_skipped
    repo = clone_project('feature')
    git('-C', repo, 'switch', '-c', 'feature')
    worktree = File.join(@temporary, 'main worktree')
    git('-C', repo, 'worktree', 'add', worktree, 'main')
    before = working_state(worktree)
    advance_remote

    stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'main is in another worktree'
    assert_equal @initial, revision(repo, 'main')
    assert_equal before, working_state(worktree)
  end

  def test_linked_worktree_with_main_can_be_updated
    repo = clone_project('original', parent: @temporary)
    git('-C', repo, 'switch', '-c', 'feature')
    worktree = File.join(@projects, 'linked main')
    git('-C', repo, 'worktree', 'add', worktree, 'main')
    feature_head = revision(repo, 'HEAD')
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal target, revision(worktree, 'HEAD')
    assert_equal feature_head, revision(repo, 'HEAD')
    assert_equal "remote update\n", File.read(File.join(worktree, 'file.txt'))
  end

  def test_rebase_in_another_worktree_is_skipped
    repo = clone_project('feature')
    git('-C', repo, 'switch', '-c', 'feature')
    worktree = File.join(@temporary, 'rebasing main')
    git('-C', repo, 'worktree', 'add', worktree, 'main')
    File.write(File.join(worktree, 'file.txt'), "conflicting local change\n")
    git('-C', worktree, 'commit', '-am', 'local commit')
    local_main = revision(repo, 'main')
    advance_remote
    git('-C', repo, 'fetch', 'origin')
    _out, _err, rebase = capture_git('-C', worktree, 'rebase', 'origin/main')
    refute rebase.success?
    before = working_state(worktree)

    stdout, _stderr, result = pull

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'Git operation in progress'
    assert_equal local_main, revision(repo, 'main')
    assert_equal before, working_state(worktree)
  end

  def test_concurrent_main_update_is_not_overwritten
    repo = clone_project('concurrent update')
    git('-C', repo, 'switch', '-c', 'feature')
    concurrent = git('-C', repo, 'commit-tree', 'main^{tree}', '-p', 'main', '-m', 'concurrent commit').strip
    target = advance_remote
    environment = fetch_environment(
      '"$PROJECTS_PULL_REAL_GIT" -C "$2" update-ref refs/heads/main "$PROJECTS_PULL_CONCURRENT_COMMIT"',
      'PROJECTS_PULL_CONCURRENT_COMMIT' => concurrent
    )

    stdout, _stderr, result = pull(environment: environment)

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'failed: update local main'
    assert_equal concurrent, revision(repo, 'main')
    assert_equal target, revision(repo, 'origin/main')
    assert_equal @initial, revision(repo, 'HEAD')
  end

  def test_switching_to_main_during_fetch_does_not_update_its_worktree
    repo = clone_project('branch changes')
    git('-C', repo, 'switch', '-c', 'feature')
    advance_remote
    environment = fetch_environment('"$PROJECTS_PULL_REAL_GIT" -C "$2" switch main')

    stdout, _stderr, result = pull(environment: environment)

    assert_equal 1, result.exitstatus
    assert_includes stdout, 'current branch changed during fetch'
    assert_equal @initial, revision(repo, 'main')
    assert_equal 'main', git('-C', repo, 'branch', '--show-current').strip
    assert_equal "initial\n", File.read(File.join(repo, 'file.txt'))
  end

  def test_only_direct_visible_directories_are_scanned
    normal = clone_project('normal')
    ignored = [clone_project('node_modules'), clone_project('.hidden')]
    nested_parent = File.join(@projects, 'container')
    FileUtils.mkdir_p(nested_parent)
    ignored << clone_project('nested', parent: nested_parent)
    outside = clone_project('outside', parent: @temporary)
    ignored << outside
    File.symlink(outside, File.join(@projects, 'symlink'))
    target = advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal target, revision(normal, 'main')
    ignored.each { |repo| assert_equal @initial, revision(repo, 'main') }
    assert_includes stdout, 'ignored: not a Git repo'
    assert_includes stdout, '非 Git 目录 1'
  end

  def test_fetch_configuration_cannot_prune_unrelated_refs_or_tags
    git('-C', @remote, 'branch', 'keep-remote')
    repo = clone_project('configured fetch')
    git('-C', repo, 'tag', 'keep-local')
    git('-C', @remote, 'branch', '-D', 'keep-remote')
    %w[fetch.prune fetch.pruneTags remote.origin.prune remote.origin.pruneTags].each do |key|
      git('-C', repo, 'config', key, 'true')
    end
    advance_remote

    stdout, stderr, result = pull

    assert result.success?, stdout + stderr
    assert_equal @initial, revision(repo, 'refs/tags/keep-local')
    assert_equal @initial, revision(repo, 'refs/remotes/origin/keep-remote')
  end

  def test_explicit_parent_directory_with_spaces
    directory = File.join(@temporary, 'other projects')
    FileUtils.mkdir_p(directory)
    repo = clone_project('project with spaces', parent: directory)
    target = advance_remote
    stdout, stderr, result = pull(directory)
    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'main')
  end

  def test_relative_parent_directory_and_callers_working_directory
    repo = clone_project('relative directory')
    target = advance_remote
    command = <<~'ZSH'
      source "$HOME/.config/warp-commands/projects-pull.zsh"
      builtin cd "$HOME" || exit
      projects-pull codex || exit
      [[ "$PWD" == "$HOME" ]]
    ZSH

    stdout, stderr, result = shell(command)

    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'main')
  end

  def test_installer_is_repeatable_and_loads_function_immediately
    config = File.join(@home, '.zshrc')
    File.open(config, 'a') { |file| file.puts('# user configuration') }
    stdout, stderr, result = shell(INSTALL + "\nprojects-pull --help")
    assert result.success?, stdout + stderr
    assert_includes stdout, '用法：projects-pull'
    contents = File.read(config)
    assert_equal 1, contents.scan('source "$HOME/.config/warp-commands/projects-pull.zsh"').length
    assert_includes contents, '# user configuration'
  end

  def test_installer_respects_zdotdir
    directory = File.join(@temporary, 'zsh config')
    FileUtils.mkdir_p(directory)
    stdout, stderr, result = shell(INSTALL, environment: { 'ZDOTDIR' => directory })
    assert result.success?, stdout + stderr
    assert_includes File.read(File.join(directory, '.zshrc')), 'projects-pull.zsh'
  end

  def test_wrapper_requires_installation_and_then_calls_function
    stdout, stderr, result = shell(WORKFLOW)
    refute result.success?
    assert_includes stderr, 'setup projects pull'
    assert_empty stdout
    repo = clone_project('wrapper')
    target = advance_remote
    command = WORKFLOW.sub('{{directory}}', '$HOME/codex')
    stdout, stderr, result = shell('source "$HOME/.config/warp-commands/projects-pull.zsh"' + "\n" + command)
    assert result.success?, stdout + stderr
    assert_equal target, revision(repo, 'main')
  end

  def test_invalid_input_and_empty_parent_directory
    _stdout, _stderr, result = pull('one', 'two')
    assert_equal 2, result.exitstatus
    _stdout, stderr, result = pull(File.join(@temporary, 'missing'))
    assert_equal 1, result.exitstatus
    assert_includes stderr, '项目目录不存在或无法读取'
    stdout, stderr, result = pull
    assert result.success?, stdout + stderr
    assert_includes stdout, '更新 0'
  end

  private

  def shell(command, *arguments, environment: {})
    Open3.capture3(@environment.merge(environment), 'zsh', '-f', '-c', command, 'test', *arguments)
  end

  def pull(*arguments, environment: {})
    shell('source "$HOME/.config/warp-commands/projects-pull.zsh"; projects-pull "$@"',
          *arguments, environment: environment)
  end

  def capture_git(*arguments)
    Open3.capture3(@environment, 'git', *arguments)
  end

  def fetch_environment(action, extra = {})
    real_git, = shell('command -v git')
    directory = File.join(@temporary, 'bin')
    FileUtils.mkdir_p(directory)
    shim = File.join(directory, 'git')
    File.write(shim, <<~ZSH)
      #!/bin/zsh
      if [[ "$3" == fetch ]]; then
        "$PROJECTS_PULL_REAL_GIT" "$@" || exit $?
        #{action}
      else
        exec "$PROJECTS_PULL_REAL_GIT" "$@"
      fi
    ZSH
    File.chmod(0o755, shim)
    {
      'PATH' => directory + File::PATH_SEPARATOR + ENV.fetch('PATH'),
      'PROJECTS_PULL_REAL_GIT' => real_git.strip
    }.merge(extra)
  end

  def git(*arguments)
    stdout, stderr, result = capture_git(*arguments)
    assert result.success?, "git #{arguments.join(' ')}\n#{stdout}#{stderr}"
    stdout
  end

  def revision(repo, ref)
    git('-C', repo, 'rev-parse', '--verify', ref).strip
  end

  def clone_project(name, parent: @projects)
    repo = File.join(parent, name)
    git('clone', @remote, repo)
    repo
  end

  def advance_remote
    File.write(File.join(@remote, 'file.txt'), "remote update\n")
    git('-C', @remote, 'commit', '-am', 'remote update')
    revision(@remote, 'main')
  end

  def working_state(repo)
    %w[HEAD].map { |ref| revision(repo, ref) } + [
      git('-C', repo, 'rev-parse', '--symbolic-full-name', 'HEAD'),
      git('-C', repo, 'status', '--porcelain', '--untracked-files=all'),
      git('-C', repo, 'diff'), git('-C', repo, 'diff', '--cached')
    ]
  end
end
