require 'azimux/hash_association_proxy'

::ActiveRecord::Base.class_eval do
  include Azimux::HashAssociationProxy::ActiveRecordExtensions
end