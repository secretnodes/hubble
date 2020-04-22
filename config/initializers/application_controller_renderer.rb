# Be sure to restart your server when you modify this file.

ActiveSupport::Reloader.to_prepare do
  ApplicationController.renderer.defaults.merge!(
    http_host: Rails.application.secrets[:application_host],
    https: Rails.application.secrets[:application_protocol] == 'https'
  )
end
