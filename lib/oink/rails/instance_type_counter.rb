module Oink
  module InstanceTypeCounter
    def self.included(klass)
      ActiveRecord::Base.send(:include, OinkInstanceTypeCounterInstanceMethods)
    
      klass.class_eval do
        after_filter :report_instance_type_count
      end
    end

    private

      def report_instance_type_count
        if logger
          breakdown = ActiveRecord::Base.instantiated_hash.sort{|a,b| b[1]<=>a[1]}.collect {|k,v| "#{k}: #{v}" }.join(" | ")
          logger.info("Instantiation Breakdown: #{breakdown}")
          ActiveRecord::Base.reset_instance_type_count
        end
      end

  end

  module OinkInstanceTypeCounterInstanceMethods
  
    def self.included(klass)
      raise "Oink does not support cache_classes being false currently" if !Rails.configuration.cache_classes
      klass.class_eval do
      
        @@instantiated_hash = {}
      
        if klass.instance_methods.include?("after_initialize")
          alias_method_chain :after_initialize, :instance_type_count
        else
          define_method :after_initialize do
            _instance_counter_after_initialize
          end
        end
      
        def self.reset_instance_type_count
          @@instantiated_hash = {}
        end
      
        def self.instantiated_hash
          @@instantiated_hash
        end
      
      end
    end
  
    def _instance_counter_after_initialize
      @@instantiated_hash[self.class.base_class.name] ||= 0
      @@instantiated_hash[self.class.base_class.name] = @@instantiated_hash[self.class.base_class.name] + 1    
    end
  
    def after_initialize_with_instance_type_count
      after_initialize_without_instance_type_count
      _instance_counter_after_initialize
    end
  
  end
end