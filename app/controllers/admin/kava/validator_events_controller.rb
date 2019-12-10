class Admin::Kava::ValidatorEventsController < Admin::Common::ValidatorEventsController
  prepend_before_action -> { @namespace = ::Kava }
end
