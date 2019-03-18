require 'write_xlsx'
require 'set'
require 'pry'

INPUT_DIR = 'logs'
TYPES_TO_LOG = %w[REQUEST RESPONSE REQUEST_CANCEL ERROR]

data = []
workbook = WriteXLSX.new('output.xlsx')
Dir.chdir(INPUT_DIR)
# binding.pry
total = Dir['*'].length
row = col = 0
worksheet = workbook.add_worksheet('sheet0')
Dir['*'].each.with_index do |file_name,index|
  begin
    file_path = file_name

    puts "#{index}/#{total} #{file_name}"
    
    meta = Hash.new

    File.open(file_path).each.with_index {|line, index| 
      /^\[(?<time>.*?)\](\[.*?\])\[(?<appVersion>.*?)\](\[.*?\]){2}\[(?<osVersion>.*?)\].*\[((?<actionType>\w*).{3}(?<action>.*).*?)\]/ =~ line
      
      next if action.nil?

      line_data = Hash.new
      line_data['fileName'] = file_name
      line_data['appVersion'] = appVersion
      line_data['osVersion'] = osVersion
      line_data['line'] = index+1 
      line_data['time'] = time
      line_data['actionType'] = actionType

      action_props = action.split('::').map{|prop| prop.split(':', 2)} 
      if action_props.length > 1 
        action_props.each{|p| line_data[p.first.strip] = p.last.strip}
      else
        line_data['value'] = action_props.flatten.join
      end

      #binding.irb if line.include?('/rko ') && line.include?('POST') && line.include?('RESPONSE') && line.include?('false')
      isError = actionType == 'ERROR' || actionType == 'ALERT' ||
        (!line_data['body'].nil? && line_data['body'].include?("\\\"success\\\":false")) ||
        (!line_data['responseStatus'].nil? && line_data['responseStatus'][0] != '2')

      data << line_data if isError
    }

  rescue StandardError => e  
     puts "не удалось прочитать файл #{file_name} #{e.message}"
  end
end

headers = data.map(&:keys).reduce(Set[],:merge)

headers.each_with_index do |header,index| 

  worksheet.write(row, index, header)
end

headers = headers.to_a.map.with_index{|item,index| [item,index]}.to_h

row += 1 

data.each do |line|
  line.each {|key,value|
  worksheet.write(row, headers[key], value)
  }
  row += 1
end
workbook.close

File.rename ('output.xlsx'), ('../output.xlsx')