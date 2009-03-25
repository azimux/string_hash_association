module Azimux
  class HashAssociationProxy
    attr_accessor :target_class
    attr_accessor :primary_key
    attr_accessor :foreign_key_column
    attr_accessor :key_column
    attr_accessor :value_column
    attr_accessor :owner

    private :target_class, :primary_key, :key_column, :value_column, :owner

    public
    def initialize association_name, owner, options
      self.owner = owner
      self.target_class = (options[:class_name] || infer_target_class(association_name)).constantize
      self.primary_key = options[:primary_key] || owner.id
      self.foreign_key_column = options[:foreign_key] || infer_foreign_key_column(owner)
      self.key_column = options[:key_column] || 'key'
      self.value_column = options[:value_column] || 'value'
    end

    def [] key
      g_hash_cache[key] if owner.new_record?

      row ||= g_hash_cache[key]

      if row.nil?
        row = g_hash_cache[key] ||= row_by_key(key)
      end

      row && row.send(value_column)
    end

    def []= key, value
      g_hash_cache[key] ||= row_by_key

      row ||= g_hash_cache[key] ||= target_class.new(key_column => key,
        value_column => value, foreign_key_column => primary_key)

      g_hash_cache[key].save unless new_record?
      value
    end

    def each_pair
      g_hash_cache.fully_load

      g_hash_cache.each_pair do |key,value|
        yield key, value.send(value_column)
      end
    end

    def row_by_key(key)
      target_class.find(:first, :conditions => ["#{key_column} = ? AND #{foreign_key_column} = ?", key, primary_key])
    end

    def clear
      target_class.delete_all(["#{foreign_key_column} = ?", primary_key])
      g_hash_cache.clear
    end

    def delete(key)
      g_hash_cache.delete(key)
      row = row_by_key(key)

      if row
        retval = row.send(value_column)
        row.destroy
        retval
      end
    end

    def save
      g_hash_cache.values.each do |value|
        if value.new_record? || value.send(association.foreign_key_column) != id
          value.send("#{foreign_key_column}=", id)
          value.save(true)
        end
      end
    end

    def models
      g_hash_cache.values
    end

    private
    def g_hash_cache
      @g_hash_cache ||= {}
    end
    def fully_load
      unless fully_loaded?
        target_class.find(:first, :conditions => ["#{foreign_key_column} = ?", primary_key]).each do |row|
          g_hash_cache[row.send(key_column)] ||= row
        end

        @fully_loaded = true
      end
    end

    def fully_loaded?
      @fully_loaded ||= false
    end

    %w(infer_target_class
      infer_foreign_key_column
      infer_owner_table
      infer_column_type
    ).each do |m|
      define_method m do |arg|
        self.class.send(m, arg)
      end
    end

    %w(col_types).each do |m|
      define_method m do
        self.class.send(m)
      end
    end


    def self.infer_target_class association_name
      association_name.to_s.singularize.camelize
    end

    def self.infer_foreign_key_column owner
      owner.class.to_s.foreign_key
    end

    def self.col_types
      %w(integer string text boolean)
    end
    def self.infer_owner_table name
      if name.to_s =~ /^(\S*)_(?:#{col_types.join("|")})_options$/
        $1.pluralize
      end
    end
    def self.infer_column_type name
      if name.to_s =~ /^\S*_(#{col_types.join("|")})_options$/
        $1
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  def self.has_hash association_name, options = {}
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