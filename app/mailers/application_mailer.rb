class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  default from: "Figment Networks#{" (#{Rails.env})" unless Rails.env.production?} <notifications@figment.network>"
  layout 'mailer'
end
