class Admin::Cosmos::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Cosmos }
end
