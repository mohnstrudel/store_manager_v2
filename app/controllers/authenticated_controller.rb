class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession
end
