DataMapper::Resource.send :include, AsyncObserver::Extensions

module DataMapper::Resource::ClassMethods
  def async_hook_seq
    @async_hook_seq ||= 0
    @async_hook_seq += 1
  end

  def async_after(target_method, method_sym = nil, &block)
    seq = async_hook_seq
    @async_hooks = []
    @async_hooks[seq] = block
    ahook = :"_async_after_#{target_method}_#{seq}"

    # DataMapper hooks don't take that extra param, the current object
    # is just supposed to be available in self.
    code = "def #{ahook}; @async_hooks[#{seq}].call; end"
    instance_eval(code, __FILE__, __LINE__ - 1)

    after target_method do
      async_send(ahook)
    end
  end

  def send_to_instance(id, selector, *args)
    x = get(id)
    x.send(selector, *args) if x
  end

  def async_each_opts(selector, opts, *args)
    min = opts.fetch(:min, minimum(:id))
    max = opts.fetch(:max, maximum(:id))

    (min..max).async_each_opts(self, :send_to_instance, opts, selector, *args)
  end

  def async_each(selector, *args)
    async_each_opts(selector, {}, *args)
  end
end
