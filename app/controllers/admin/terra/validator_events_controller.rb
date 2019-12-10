class Admin::Terra::ValidatorEventsController < Admin::Common::ValidatorEventsController
  prepend_before_action -> { @namespace = ::Terra }
end
