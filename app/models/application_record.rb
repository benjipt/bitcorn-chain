# ActiveRecord::Base is the super class of all models in Rails.
# We can define a primary abstract class for all models to inherit from.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
