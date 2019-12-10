class Admin::Cosmos::ValidatorEventsController < Admin::Common::ValidatorEventsController
  prepend_before_action -> { @namespace = ::Cosmos }
end
