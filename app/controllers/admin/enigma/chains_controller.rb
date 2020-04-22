class Admin::Enigma::ChainsController < Admin::Common::ChainsController
  prepend_before_action -> { @namespace = ::Enigma }
end
