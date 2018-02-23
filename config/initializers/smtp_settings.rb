secrets=YAML.load_file('secrets.yml')

ActionMailer::Base.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => "587",
    :domain => "gmail.com",
    :user_name => secrets['gmailAddress'],
    :password => secrets['gmailPassword'],
    :authentication => "plain",
    :enable_starttls_auto => true
}
