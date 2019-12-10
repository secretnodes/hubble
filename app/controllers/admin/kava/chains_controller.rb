class Admin::Kava::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Kava }
end
