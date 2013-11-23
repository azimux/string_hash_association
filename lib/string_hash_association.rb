module StringHashAssociation
  class Engine < Rails::Engine
    config.autoload_paths << File.expand_path("..", __FILE__)

    initializer "string_hash_association" do
      require 'azimux/hash_association_proxy'

      ::ActiveRecord::Base.class_eval do
        include Azimux::HashAssociationProxy::ActiveRecordExtensions
      end
    end
  end
end
