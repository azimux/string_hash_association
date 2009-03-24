module Azimux
  class HashAssociationProxy
    module Migration
      def add_hash_association_table name, options = {}
        owner = options[:owner] || HashAssociationProxy.infer_owner_table(name).singularize
        type = options[:type] || HashAssociationProxy.infer_column_type(name)

        ownerid = owner + "_id"

        fk = nil

        #if user explicitly set :owner_table to nil, then don't use a foreign key
        unless options.include?(:owner_table) && !options[:owner_table]
          fk = options[:owner_table] || HashAssociationProxy.infer_owner_table(name)
        end

        create_table name do |t|
          t.string :name, :null => false
          t.send(type, :value)
          t.integer ownerid, :null => false, :deferrable => true,
            :references => fk
        end

        add_index name, [ownerid, :name], :unique => true
      end

      def remove_hash_association_table name
        drop_table(name)
      end
    end
  end
end