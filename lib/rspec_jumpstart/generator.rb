# frozen_string_literal: true

require "rdoc"
require "rspec_jumpstart"
require "rspec_jumpstart/erb_factory"
require "rspec_jumpstart/erb_templates"
require "rspec_jumpstart/rdoc_factory"

#
# RSpec Code Generator
#
module RSpecJumpstart
  class Generator
    include RSpecJumpstart::ERBTemplates

    attr_accessor :spec_dir, :delta_template, :full_template

    def initialize(spec_dir = "./spec", delta_template = nil, full_template = nil)
      @spec_dir       = spec_dir.gsub(%r{/$}, "")
      @delta_template = delta_template
      @full_template  = full_template
    end

    #
    # Writes new spec or appends to the existing spec.
    #
    def write_spec(file_path, force_write: false, dry_run: false, rails_mode: false)
      begin
        code            = ""
        class_or_module = RSpecJumpstart::RDocFactory.get_rdoc_class_or_module(file_path)
        if class_or_module
          spec_path = get_spec_path(file_path)

          code = if force_write && File.exist?(spec_path)
                   append_to_existing_spec(class_or_module, dry_run, rails_mode, file_path, spec_path)
                 else
                   create_new_spec(class_or_module, dry_run, rails_mode, file_path, spec_path)
                 end
        else
          puts red("#{file_path} skipped (Class/Module not found).")
        end
      rescue StandardError => e
        puts red("#{file_path} aborted - #{e.message}")
      end

      code
    end

    #
    # Gets the complete class name from RDoc::NormalClass/RDoc::NormalModule instance.
    #
    def get_complete_class_name(class_or_module, name = class_or_module.name)
      if class_or_module.parent.name && class_or_module.parent.is_a?(RDoc::NormalModule)
        get_complete_class_name(class_or_module.parent, "#{class_or_module.parent.name}::#{name}")
      else
        name
      end
    end

    def to_string_namespaced_path(self_path)
      path = self_path.split("/").map { |x| camelize(x) }[1..-2].uniq.join("::")
      path.empty? ? "" : "#{path}::"
    end

    def to_string_namespaced_path_whole(self_path)
      self_path.
        sub(".rb", "").
        split("/").
        map { |x| camelize(x) }[2..].
        uniq.
        join("::")
    end

    def decorated_name(method)
      (method.singleton ? "." : "#") + method.name
    end

    #
    # Returns spec file path.
    # e.g. "lib/foo/bar_baz.rb" -> "spec/foo/bar_baz_spec.rb"
    #
    def get_spec_path(file_path)
      "#{spec_dir}/" \
        "#{file_path.gsub(%r{^\./}, '').gsub(%r{^(lib/)|(app/)}, '').sub(/\.rb$/, '_spec.rb')}"
    end

    #
    # Returns string value to require.
    # e.g. "lib/foo/bar_baz.rb" -> "foo/bar_baz"
    #
    def to_string_value_to_require(file_path)
      file_path.gsub(%r{^(lib/)|(app/)}, "").gsub(/\.rb$/, "")
    end

    #
    # Returns snake_case name.
    # e.g. FooBar -> "foo_bar"
    #
    def instance_name(klass)
      klass.name.
        gsub(/::/, "/").
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
    end

    #
    # Extracts parameter names as an *Array*.
    # e.g. "()" -> []
    # e.g. "(a, b = 'foo')" -> ["a", "b"]
    #
    def to_param_names_array(params)
      params.
        split(",").
        map { |p| p.gsub(/[()\s]/, "").gsub(/=.+$/, "") }.
        reject { |p| p.nil? || p.empty? }
    end

    #
    # Returns params part
    # e.g. ["a","b"] -> "(a, b)"
    # e.g. [] -> ""
    #
    def to_params_part(params)
      param_csv = to_param_names_array(params).join(", ")
      param_csv.empty? ? "" : "(#{param_csv})"
    end

    #
    # Creates new spec.
    #
    # rubocop:disable Metrics/AbcSize
    def create_new_spec(class_or_module, dry_run, rails_mode, file_path, spec_path)
      # These names are used in ERB template, don't delete.
      methods_to_generate       = public_methods_found(class_or_module)
      scope_methods_to_generate = scopes(class_or_module, file_path, spec_path)
      c                         = class_or_module
      self_path                 = to_string_value_to_require(file_path)
      erb  = RSpecJumpstart::ERBFactory.
             new(@full_template).
             get_instance_for_new_spec(rails_mode, file_path)
      code = erb.result(binding)

      if dry_run
        puts "----- #{spec_path} -----"
        puts code
      elsif File.exist?(spec_path)
        # puts yellow("#{spec_path} already exists.")
      else
        FileUtils.mkdir_p(File.dirname(spec_path))
        File.open(spec_path, "w") { |f| f.write(code) }
        puts green("#{spec_path} created.")
      end

      code
    end

    def public_methods_found(class_or_module)
      class_or_module.method_list.select do |m|
        m.visibility.equal?(:public) && m.name != "new"
      end
    end

    # rubocop:enable Metrics/AbcSize

    #
    # Appends new tests to the existing spec.
    #
    # rubocop:disable Metrics/AbcSize
    def append_to_existing_spec(class_or_module, dry_run, rails_mode, file_path, spec_path)
      existing_spec = File.read(spec_path)
      if skip?(existing_spec)
        return
      end

      lacking_methods = public_methods_found(class_or_module).
                        reject { |m| existing_spec.match(signature(m)) }

      scope_methods_to_generate = scopes(class_or_module, file_path, spec_path)
      return if lacking_methods.empty? && scope_methods_to_generate.empty?

      # These names are used in ERB template, don't delete.
      methods_to_generate = lacking_methods
      c                   = class_or_module
      erb = RSpecJumpstart::ERBFactory.
            new(@delta_template).
            get_instance_for_appending(rails_mode, spec_path)
      additional_spec = erb.result(binding).strip

      last_end_not_found = true
      code               = existing_spec.split("\n").reverse.reject do |line|
        before_modified    = last_end_not_found
        last_end_not_found = line.gsub(/#.+$/, "").strip != "end" if before_modified
        before_modified
      end.reverse.join("\n")

      unless additional_spec.empty?
        code += "\n#{additional_spec}\n"
      end

      code += "\nend\n"

      if dry_run
        puts "----- #{spec_path} -----"
        puts code
      else
        File.open(spec_path, "w") { |f| f.write(code) }
      end
      puts green("#{spec_path} modified.")

      code
    end

    def skip?(text)
      RSpecJumpstart.config.behaves_like_exclusions.each do |exclude_pattern|
        return true if text.match(exclude_pattern)
      end

      false
    end

    # rubocop:enable Metrics/AbcSize

    # -----
    # Code generation
    # -----

    #
    # e.g.
    #     a = double('a')
    #     b = double('b')
    #     bar_baz = BarBaz.new(a, b)
    #
    def get_instantiation_code(klass, method)
      return "" if method.singleton

      constructor = klass.method_list.find { |m| m.name == "new" }
      if constructor.nil?
        "      #{instance_name(klass)} = described_class.new\n"
      else
        get_params_initialization_code(constructor) +
          "      #{instance_name(klass)} = described_class.new#{to_params_part(constructor.params)}\n"
      end
    end

    #
    # e.g.
    #     a = double('a')
    #     b = double('b')
    #
    def get_params_initialization_code(method)
      code = to_param_names_array(method.params).map do |p|
        x = p.sub("*", "").sub("&", "")
        "      #{x} = double('#{x}')" unless x.empty?
      end.compact.join("\n")
      code.empty? ? "" : "#{code}\n"
    end

    #
    # e.g. BarBaz.do_something(a, b) { |c| }
    #
    def get_method_invocation_code(klass, method)
      target = method.singleton ? "described_class" : instance_name(klass)
      "#{target}.#{method.name}#{to_params_part(method.params)}#{get_block_code(method)}"
    end

    #
    # e.g. do_something(a, b) { |c| }
    #
    def get_rails_helper_method_invocation_code(method)
      "#{method.name}#{to_params_part(method.params)}#{get_block_code(method)}"
    end

    #
    # e.g. { |a, b| }
    #
    def get_block_code(method)
      return "" if method.block_params.nil? || method.block_params.empty?

      " { |#{method.block_params}| }"
    end

    def get_rails_http_method(method_name)
      RAILS_RESOURCE_METHOD_AND_HTTP_METHOD[method_name] || "get"
    end

    private

    def parse_sexp(sexp, scopes, methods, stack = [])
      case sexp[0]
        when :module
          parse_sexp(sexp[2], scopes, methods, stack + [sexp[0], sexp[1][1][1]])

        when :vcall
          name = sexp[1][1]
          return if name.eql?("private")

        when :command
          if sexp[1][0] == :@ident && sexp[1][1] == "scope"
            name = sexp[2][1][0][1][1][1]
            scopes << name
          end

        when :class
          parse_sexp(sexp[3], scopes, methods, stack + [sexp[0], sexp[1][1][1]])

        when :def
          name = sexp[1][1]
          # line_number = sexp[1][2][0]

          parse_sexp(sexp[3], scopes, methods, stack + [sexp[0], sexp[1][1]])

          # puts "#{line_number}: Method: #{stack.last}##{name}\n"
          methods << name
        else
          if sexp.is_a?(Array)
            sexp.each { |s| parse_sexp(s, scopes, methods, stack) if s.is_a?(Array) }
          end
      end
    end

    require "ripper"

    def scopes(_klass, file_path, spec_path)
      content      = File.read(file_path)
      spec_content = (
      begin
        File.read(spec_path)
      rescue StandardError
        ""
      end)
      sexp         = Ripper.sexp(content)
      methods      = []
      scopes       = []

      parse_sexp(sexp, scopes, methods)

      scope_methods = []
      scopes.each do |method|
        unless spec_content.include?("'.#{method}'")
          scope_methods << method
        end
      end

      scope_methods
    end

    def signature(method)
      "'#{decorated_name(method).sub('?', '\?').gsub('[', '\[').gsub(']', '\]')}'"
    end

    def colorize(text, color_code)
      "#{color_code}#{text}\033[0m"
    end

    def red(text)
      colorize(text, "\033[31m")
    end

    def green(text)
      colorize(text, "\033[32m")
    end

    def blue(text)
      colorize(text, "\033[34m")
    end

    def yellow(text)
      colorize(text, "\033[33m")
    end

    def camelize(str)
      str.split("_").map { |w| w.capitalize }.join
    end

    RAILS_RESOURCE_METHOD_AND_HTTP_METHOD = {
      "index" => "get",
      "new" => "get",
      "create" => "post",
      "show" => "get",
      "edit" => "get",
      "update" => "patch",
      "destroy" => "delete"
    }.freeze

  end
end

