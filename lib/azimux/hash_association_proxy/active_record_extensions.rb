module Azimux
  class HashAssociationProxy
    module ActiveRecordExtensions
      extend ActiveSupport::Concern

      module ClassMethods
        def has_hash association_name, options = {}
          define_method association_name do
            instance_variable_get("@#{association_name}_hash_proxy") ||
              instance_variable_set("@#{association_name}_hash_proxy",
              Azimux::HashAssociationProxy.new(association_name, self, options))
          end

          define_method "#{association_name}=" do |hash|
            s_hash = self.send("#{association_name}_hash_proxy")
            s_hash.clear

            hash.each_pair do |key,value|
              s_hash[key] = value
            end
            s_hash
          end

          method_name = "after_save_for_#{association_name}".to_sym
          define_method(method_name) do
            association = instance_variable_get("@#{association_name}_hash_proxy")

            association.save if !association.nil? && new_record?
          end
          after_save method_name
        end
      end
    end
  end
end