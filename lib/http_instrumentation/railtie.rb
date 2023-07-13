# frozen_string_literal: true

module HTTPInstrumentation
  class Railtie < Rails::Railtie
    config.before_initialize do
      HTTPInstrumentation.initialize!
    end
  end
end
