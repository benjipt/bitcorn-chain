class ApplicationController < ActionController::API
  before_action :transform_request_parameters

  private

  def transform_request_parameters
    params.transform_keys!(&:underscore)
    params.deep_transform_keys!(&:underscore)
  end
end
