# Generator for use in Merb
class AsyncWorkerGenerator < Merb::GeneratorBase

  def initialize(args, options = {})
    super
    @worker_name = args[0]
  end
  
  def manifest
    record do |m|
      m.directory 'lib'
      m.file "async_worker.rb", File.join('lib', "#{@worker_name}.rb")
    end
  end
  
  protected
  def banner
    <<-EOS.split("\n").map{|x| x.strip}.join("\n")
      Creates a worker script

      USAGE: #{spec.name}"
    EOS
  end
      
end
