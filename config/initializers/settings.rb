Rails.application.config.time_zone = "CST"

WX = YAML.load_file(Rails.root.join('config', 'weixin.yml'))[Rails.env]
