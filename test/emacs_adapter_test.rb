# frozen_string_literal: true

require_relative "test_helper"

class EmacsAdapterTest < Minitest::Test
  ESSENTIAL_FACES = %w[
    default cursor region mode-line line-number font-lock-keyword-face
    fixed-pitch fixed-pitch-serif variable-pitch menu custom-group-tag
    font-lock-doc-face isearch lazy-highlight show-paren-match
    completions-highlight diff-added diff-removed compilation-error
    flymake-error dired-directory ansi-color-red org-level-1 org-block
    org-todo corfu-current company-tooltip-selection vertico-current
    magit-diff-added magit-diff-removed markdown-header-face
    org-modern-block-name transient-enabled-suffix racket-keyword-argument-face
    marginalia-documentation marginalia-file-name marginalia-mode
    smerge-upper shr-selected-link dired-subtree-depth-1-face elisp-condition
  ].freeze

  def setup
    @theme = Lacold.themes(colors: ["blue"], modes: [:dark]).first
    @content = Lacold::Adapters.find("emacs").render([@theme]).first.content
  end

  def test_theme_covers_core_emacs_and_common_packages
    faces = @content.scan(/^   '\(([^ ]+)/).flatten

    assert_empty ESSENTIAL_FACES - faces
    assert_equal faces.uniq, faces
    assert_operator faces.size, :>=, 440
  end

  def test_theme_declares_color_scheme_metadata
    assert_includes @content, ":family 'lacold :kind 'color-scheme :background-mode 'dark"
  end

  def test_modern_font_lock_roles_have_visible_hierarchy
    assert_includes @content, "'(font-lock-property-use-face ((t (:foreground \"#{@theme.secondary}\"))))"
    assert_includes @content, "'(font-lock-string-face ((t (:foreground \"#{@theme.fg}\"))))"
    assert_includes @content, "'(font-lock-constant-face ((t (:foreground \"#{@theme.fg}\"))))"
  end

  def test_active_mode_line_inherits_the_base_face
    assert_includes @content, "'(mode-line-active ((t (:inherit mode-line))))"
    assert_includes @content, "'(mode-line-inactive ((t (:foreground \"#{@theme.muted}\" :background \"#{@theme.surface}\" :box nil))))"
  end

  def test_org_headlines_use_a_neutral_typographic_hierarchy
    assert_includes @content, "'(org-level-1 ((t (:foreground \"#{@theme.primary}\" :weight bold :height 1.2))))"
    assert_includes @content, "'(org-level-2 ((t (:foreground \"#{@theme.secondary}\" :weight semi-bold :height 1.15))))"
    assert_includes @content, "'(org-level-3 ((t (:foreground \"#{@theme.secondary}\" :weight normal :height 1.1))))"
    refute_match(/org-level-[1-8].*:foreground \"#{Regexp.escape(@theme.fg)}\"/, @content)
  end

  def test_theme_uses_only_authored_lacold_colors
    allowed = @theme.colors.values.uniq
    generated = @content.scan(/#[0-9A-F]{6}/).uniq

    assert_empty generated - allowed
  end
end
