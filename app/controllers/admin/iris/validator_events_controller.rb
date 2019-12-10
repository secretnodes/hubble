class Admin::Iris::ValidatorEventsController < Admin::Common::ValidatorEventsController
  prepend_before_action -> { @namespace = ::Iris }
end
