class Admin::Iris::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Iris }
end
