ActiveRecord::Base.class_eval do
  def self.has_string_hash association_name, options = {}
    define_method association_name do
      read_instance_variable("#{association_name}_string_hash_proxy") ||
        write_instance_variable("#{association_name}_string_hash_proxy",
        Azimux::StringHashAssociation.new(association_name, self, options))
    end

    method_name = "after_save_for_#{association_name}".to_sym
    define_method(method_name) do
      association = read_instance_variable("#{association_name}_string_hash_proxy")

      association.save if !association.nil? && new_record?
    end
    after_save method_name
  end
end
