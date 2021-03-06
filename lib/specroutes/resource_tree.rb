module Specroutes
  class ResourceTree
    class Error < ::StandardError; end
    class DoesNotFitError < Error; end

    WITHOUT_LAST_SLASH_RE = %r{/(?=[^/])}

    attr_reader :payload, :path_portion, :parent, :children

    def self.from_resource_list(resources)
      root_node = ResourceTree.new('/')
      resources.sort_by(&:path).each do |resource|
        root_node.branch!(resource.path, resource)
      end
      root_node
    end

    def initialize(path_portion, parent=nil)
      @path_portion = path_portion
      @payload = []
      @children = []
      @parent = parent
      parent.register(self) if parent
    end

    def register(node)
      children << node
      node
    end

    def path
      @path or path!
    end

    def path!
      @path = "#{parent && parent.path}#{path_portion}"
    end

    def depth
      @depth or depth!
    end

    def depth!
      @depth = parent ? parent.depth + 1 : 0
    end

    def branch!(resource_path, resource)
      if resource_path.start_with?(path)
        portions = resource_path.sub(path, '').split(WITHOUT_LAST_SLASH_RE)
        node = portions.reduce(self) { |n, p| n.child_for!(p, n) }
        node.payload << resource
      else
        branch_from_parent!(resource_path, resource)
      end
    end

    def branch_from_parent!(resource_path, resource)
      if parent
        parent.branch!(resource_path, resource)
      else
        raise DoesNotFitError.new("#{resource_path} does not fit.")
      end
    end

    def child_for!(portion, node)
      child = children.find { |c| c.path_portion == portion }
      child or ResourceTree.new(portion, node)
    end

    def each_node(&block)
      if block_given?
        block.call(self) if parent
        children.each { |c| c.each_node(&block) }
      end
    end
  end
end
