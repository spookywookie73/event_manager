require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(homephone)
  # use gsub to remove non-digits from number
  extract_numbers = homephone.gsub(/\D/, '')
  # check to make sure number matches all conditions
  if (extract_numbers.length == 11) && (extract_numbers.start_with? "1")
    extract_numbers[1..-1]
  elsif extract_numbers.length == 10
    extract_numbers
  else
    "- Not a valid Phone Number -"
  end
end

def count(list)
  # create a hash
  counts = Hash.new(0)
  # count how many times a number appears
  list.each { |num| counts[num] += 1 }
  # display text with relevant numbers
  counts.each do |k,v|
    if v == 1
      puts "#{v} person registered at #{k}"
    else
      puts "#{v} people registered at #{k}"
    end
  end
end


def what_day(days)
  weekdays = { 0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday" }
  # count how many days appear the most and display a message
  day_of_week = days.max_by { |day| days.count(day)}
  puts "\nThe most common registration day is: #{weekdays[day_of_week]}."
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
regday = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  homephone = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  regdate = row[:regdate]
  # push the hour from a date and time array to an empty array
  regtime.push(DateTime.strptime(regdate, "%m/%d/%y %k:%M").strftime("%k" + ":00 hrs"))
  # push the day from a date array to an empty array
  regday.push(DateTime.strptime(regdate, "%m/%d/%y").wday)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts "#{name} - phone number: #{homephone}"
end

puts "\nRegistration times: "
count(regtime)
what_day(regday)