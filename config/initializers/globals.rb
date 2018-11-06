TASK_DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S %Z'
ALERT_MINIMUM_TIMEOUT = 15.minutes

REQUIRE_HTTP_BASIC = if !Rails.application.secrets.http_basic_password.blank?
  HTTP_BASIC_USERNAME = 'hubble'
  HTTP_BASIC_PASSWORD = Rails.application.secrets.http_basic_password
  true
else
  false
end
