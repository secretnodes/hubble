class Admin::Terra::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Terra }
end
