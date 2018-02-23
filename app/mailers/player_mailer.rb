secrets=YAML.load_file('secrets.yml')

class PlayerMailer < ApplicationMailer
  def pairing_email(pairing)
    @pairing = pairing
    @to = pairing[:to]
    @from = pairing[:from]
    emails = (pairing[:to].map{|payment| payment[:player]} + pairing[:from].map{|payment| payment[:player]}).map{|player| player.email}
    # TODO fix this back up
    mail(to: 'todo', cc: "#{secrets["ccEmail"]}", subject: "Online Settlement #{Date.today.strftime("%B")} (Balance as of #{Date.today}) (Normally sent to #{emails.join(',')}")
  end
end
