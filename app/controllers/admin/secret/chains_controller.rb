class Admin::Secret::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Secret }
end
