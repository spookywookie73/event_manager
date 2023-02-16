require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(homephone)
  extract_numbers = homephone.gsub(/\D/, '')
  
  if (extract_numbers.length == 11) && (extract_numbers.start_with? "1")
    extract_numbers[1..-1]
  elsif extract_numbers.length == 10
    extract_numbers
  else
    "- Not a valid Phone Number -"
  end
end

def count(list)
  counts = Hash.new(0)
  list.each { |num| counts[num] += 1 }

  counts.each do |k,v|
    if v == 1
      puts "#{v} person registered at #{k}"
    else
      puts "#{v} people registered at #{k}"
    end
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
regtime = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  homephone = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  regdate = row[:regdate]
  regtime.push(DateTime.strptime(regdate, "%m/%d/%y %k:%M").strftime("%k" + ":00 hrs"))

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts "#{name} - phone number: #{homephone}"
end

puts "\nRegistration times: "
count(regtime)