if Rails.env.development? || ENV['FORCE_DB_SEED'].present?
  admin = Administrator.create(
    name: 'Dev Admin',
    email: 'admin@secretnodes.org',
    one_time_setup_token: SecureRandom.hex
  )
  puts "Admin created:\nhttp://localhost:3000/admin/sessions/new?token=#{admin.one_time_setup_token}"
end
