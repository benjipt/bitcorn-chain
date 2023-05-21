# ApplicationController is a controller class that inherits from ActionController::API.
# It serves as the base controller for all other controllers in the application.
# ApplicationController applies a `before_action` to transform request parameters for every request.
#
# All other controllers in the application should inherit from this controller, and any
# functionality that should be available across all controllers can be added here.
class ApplicationController < ActionController::API
  # Applies the `transform_request_parameters` method before every action
  before_action :transform_request_parameters

  private

  # `transform_request_parameters` is a private method that modifies all keys in the `params`
  # hash by replacing each key with its underscored version. This transformation is done
  # recursively for nested hashes, meaning it also applies to the keys in any hash values
  # contained within the `params` hash. The purpose of this method is to ensure consistent
  # use of underscored (snake_case) parameters throughout the application, even if the
  # incoming request provides data in camelCase or some other format.
  def transform_request_parameters
    params.transform_keys!(&:underscore)
    params.deep_transform_keys!(&:underscore)
  end
end
