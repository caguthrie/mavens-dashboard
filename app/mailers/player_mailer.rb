
class PlayerMailer < ApplicationMailer
  def pairing_email(pairing)
    secrets=YAML.load_file('secrets.yml')
    @pairing = pairing
    @to = pairing['to']
    @from = pairing['from']
    emails = (@to.map{|payment| payment['player']} + @from.map{|payment| payment['player']}).map{|player| player['email']}
    mail(to: emails, cc: secrets["ccEmail"], subject: "Online Settlement #{Date.today.strftime("%B")} (Balance as of #{Date.today})")
  end

  def going_to_game_email(offset)
    secrets=YAML.load_file('secrets.yml')
    @offset = offset
    mail(to: offset['player']['email'], cc: secrets["ccEmail"], subject: "Online Settlement at the live game #{Date.today.strftime("%B")} (Balance as of #{Date.today})")
  end
end
