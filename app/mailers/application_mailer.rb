class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  add_template_helper NamespacedChainsHelper

  default from: "secretnodes.org#{" (#{Rails.env})" unless Rails.env.production?} <notifications@secretnodes.org>"
  layout 'mailer'
end
