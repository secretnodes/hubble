Rails.application.config.assets.version = '1.0'
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.precompile += %w(
  admin.js admin.scss
  errors.scss
  account.js account.scss
  enigma.js enigma.scss
  secret.js secret.scss
  cosmos.js cosmos.scss
  terra.js terra.scss
  iris.js iris.scss
  kava.js kava.scss
)
