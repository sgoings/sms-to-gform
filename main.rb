require 'twilio-ruby'
require 'sinatra'
require 'tzinfo'

raise "TWILIO_ACCOUNT_SID environment variable not defined" if ENV['TWILIO_ACCOUNT_SID'].nil?
raise "TWILIO_ACCOUNT_TOKEN environment variable not defined" if ENV['TWILIO_ACCOUNT_TOKEN'].nil?

account_sid = ENV['TWILIO_ACCOUNT_SID']
auth_token = ENV['TWILIO_ACCOUNT_TOKEN']

client = Twilio::REST::Client.new(account_sid, auth_token)

$stdout.sync = true

get '/' do
  "SMS to Google Form Submitter 0.1.0"
end

post '/submit' do
  body = params['Body']
  from = params['From']
  to = params['To']

  puts "Received POST - From: #{from}, Body #{body}"

  guardian_name = phone_to_name(from)

  if !guardian_name.nil?
    response_code = submit_form_as(guardian_name)

    if response_code == "200"
      message = "form has been submitted as #{guardian_name}"
    else
      message = "form submission failure"
    end
  else
    message = "phone number is not recognized - could not submit form on your behalf."
  end

  puts "Sending back: ", message

  twiml = Twilio::TwiML::MessagingResponse.new do |r|
    r.message(body: message)
  end

  return twiml.to_s
end

def phone_to_name(number)
  numbers_names = {
    "+12223334444" => "John Smith",
    "+15556667777" => "Jane Doe",
  }

  if numbers_names.has_key?(number)
    puts "phone number in map"
    return numbers_names[number]
  else
    puts "phone number not in map"
  end
end

def submit_form_as(allowed_submitter)
  tz = TZInfo::Timezone.get('America/Denver')
  local_time = tz.to_local(Time.now.utc)

  form_uri = URI("https://docs.google.com/forms/<FORM URI SEGMENT>/formResponse")
  form_data = {
    "entry.40036136" => allowed_submitter,
    "entry.465155970_hour" => local_time.hour,
    "entry.465155970_minute" => local_time.min,
    "entry.532406418_year" => local_time.year,
    "entry.532406418_month" => local_time.month,
    "entry.532406418_day" => local_time.day,
  }

  puts "Submitting form with #{form_data}"
  res = Net::HTTP.post_form form_uri, form_data
  puts "Status #{res.code}"

  return res.code
end
