ActiveRecord::Base.send :include, AsyncObserver::Extensions

HOOKS = [:after_create, :after_update, :after_save]

class << ActiveRecord::Base
  HOOKS.each do |hook|
    code = %Q{def async_#{hook}(&b) add_async_hook(#{hook.inspect}, b) end}
    class_eval(code, __FILE__, __LINE__ - 1)
  end

  def add_async_hook(hook, block)
    async_hooks[hook] << block
  end

  def async_hooks
    @async_hooks ||= Hash.new do |hash, hook|
      ahook = :"_async_#{hook}"

      # This is for the producer's benefit
      send(hook){|o| async_send(ahook, o)}

      # This is for the worker's benefit
      code = "def #{ahook}(o) run_async_hooks(#{hook.inspect}, o) end"
      instance_eval(code, __FILE__, __LINE__ - 1)

      hash[hook] = []
    end
  end

  def run_async_hooks(hook, o)
    async_hooks[hook].each{|b| b.call(o)}
  end

  def send_to_instance(id, selector, *args)
    x = find_by_id(id)
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
