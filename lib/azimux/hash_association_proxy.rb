module Azimux
  class HashAssociationProxy
    attr_accessor :target_class,
      :primary_key_column,
      :foreign_key_column,
      :key_column,
      :value_column,
      :owner

    def initialize association_name, owner, options
      self.owner = owner
      self.target_class = (
        options[:class_name] || infer_target_class(association_name)
      ).constantize
      self.primary_key_column = options[:primary_key] || :id
      self.foreign_key_column =
        options[:foreign_key] || infer_foreign_key_column(owner)
      self.key_column = options[:key_column] || 'key'
      self.value_column = options[:value_column] || 'value'
    end

    def primary_key
      owner.send(primary_key_column)
    end

    def [] key
      row = g_hash_cache[key] || row_by_key(key)

      row.try(value_column)
    end

    def []= key, value
      row ||= g_hash_cache[key] ||= row_by_key(key)
      if row
        row.send("#{value_column}=", value)
      else
        row = g_hash_cache[key] ||= target_class.new(
          key_column => key,
          value_column => value, 
          foreign_key_column => primary_key
        )
      end

      row.save unless owner.new_record?
      value
    end

    def each_pair
      fully_load

      g_hash_cache.each_pair do |key, value|
        yield key, value.send(value_column)
      end
    end

    def row_by_key(key)
      target_class.where(
        ["#{key_column} = ? AND #{foreign_key_column} = ?", key, primary_key]
      ).first
    end

    def clear
      target_class.delete_all(["#{foreign_key_column} = ?", primary_key])
      g_hash_cache.clear
      @fully_loaded = false
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

    ["","!"].each do |s|
      define_method :save do
        g_hash_cache.values.each do |value|
          if value.new_record? || value.send(association.foreign_key_column) != id
            value.send("#{foreign_key_column}=", id)
            value.send("save#{s}", true)
          end
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
        target_class.where(["#{foreign_key_column} = ?", primary_key]).each do |row|
          g_hash_cache[row.send(key_column)] ||= row
        end

        @fully_loaded = true
      end
    end

    def fully_loaded?
      @fully_loaded
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


    class << self
      def self.infer_target_class association_name
        association_name.to_s.singularize.camelize
      end

      def infer_foreign_key_column owner
        owner.class.to_s.foreign_key
      end

      def col_types
        %w(integer string text boolean)
      end

      def infer_owner_table name
        if name.to_s =~ /^(\S*)_(?:#{col_types.join("|")})_options$/
          $1.pluralize
        end
      end

      def infer_column_type name
        if name.to_s =~ /^\S*_(#{col_types.join("|")})_options$/
          $1
        end
      end
    end
  end
end