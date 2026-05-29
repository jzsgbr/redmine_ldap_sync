require 'entity_manager'

module LdapSync::Infectors
  Dir[File.join(File.dirname(__FILE__), "infectors", "*.rb")].each do |file|
    require file
    infected_name = File.basename(file, ".rb").classify
    _module = const_get(infected_name)
    _class = begin
      Kernel.const_get(infected_name)
    rescue NameError
      nil
    end
    if _class && !_class.included_modules.include?(_module)
      _class.send(:include, _module)
    end
  end
end
