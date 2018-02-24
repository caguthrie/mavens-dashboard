
class PlayerMailer < ApplicationMailer
  def pairing_email(pairing)
    secrets=YAML.load_file('secrets.yml')
    @pairing = pairing
    @to = pairing[:to]
    @from = pairing[:from]
    emails = (pairing[:to].map{|payment| payment[:player]} + pairing[:from].map{|payment| payment[:player]}).map{|player| player.email}
    # TODO fix this back up
    mail(to: 'todo', subject: "Online Settlement #{Date.today.strftime("%B")} (Balance as of #{Date.today}) (Normally sent to #{emails.join(',')}")
  end
end
