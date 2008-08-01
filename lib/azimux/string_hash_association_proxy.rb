module Azimux
  class StringHashAssociationProxy
    private_attr_accessor :target_class
    private_attr_accessor :primary_key
    attr_accessor :foreign_key_column
    private_attr_accessor :key_column
    private_attr_accessor :value_column
    private_attr_accessor :owner


    def initialize association_name, owner, options
      self.target_class = options[:class_name] || infer_target_class(association_name)
      self.primary_key = options[:primary_key] || owner.id
      self.foreign_key_column = options[:foreign_key] || infer_foreign_key_column(owner)
      self.key_column = options[:key] || 'key'
      self.value_column = options[:key] || 'value'
    end

    def [] key
      string_hash_cache[key] if owner.new_record?

      row ||= string_hash_cache[key]

      if row.nil?
        row = string_hash_cache[key] ||= target_class.find(:first,
          :conditions => ["#{key_column} = ? && #{foreign_key_column} = ?", key, primary_key])
      end

      row && row.send(value_column)
    end

    def []= key, value
      string_hash_cache[key] ||= target_class.find(:first, :conditions => ["#{key_column} = ?", key])

      row ||= string_hash_cache[key] ||= target_class.new(key_column => key,
        value_column => value, foreign_key_column => primary_key)

      string_hash_cache[key].save unless new_record?
      value
    end

    def save
      string_hash_cache.values.each do |value|
        if value.new_record? || value.send(association.foreign_key_column) != id
          value.send("#{foreign_key_column}=", id)
          value.save(true)
        end
      end
    end

    private
    def string_hash_cache
      @string_hash_cache ||= {}
    end
  end
end


ActiveRecord::Base.class_eval do
  def self.has_string_hash association_name, options = {}
    define_method association_name do
      read_instance_variable("#{association_name}_string_hash_proxy") ||
        write_instance_variable("#{association_name}_string_hash_proxy",
        Azimux::StringHashAssociationProxy.new(association_name, self, options))
    end

    method_name = "after_save_for_#{association_name}".to_sym
    define_method(method_name) do
      association = read_instance_variable("#{association_name}_string_hash_proxy")

      association.save if !association.nil? && new_record?
    end
    after_save method_name
  end
end
