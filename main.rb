require 'write_xlsx'
require 'set'
# require 'pry'

INPUT_DIR = 'logs'
TYPES_TO_LOG = %w[REQUEST RESPONSE REQUEST_CANCEL ERROR]


workbook = WriteXLSX.new('output.xlsx')
Dir.chdir(INPUT_DIR)
# binding.pry
Dir['*'].each do |file_name|
  file_path = file_name
  file_data = []
  worksheet = workbook.add_worksheet(file_name.slice(0,30))
  row = col = 1
  meta = Hash.new

  # binding.pry
  worksheet.write(0, 0, file_name)
  File.open(file_path).each.with_index {|line, index| 
    /^\[(?<time>.*?)\](\[.*?\])\[(?<appVersion>.*?)\](\[.*?\]){2}\[(?<osVersion>.*?)\].*\[((?<actionType>\w*).{3}(?<action>.*).*?)\]/ =~ line
    next unless TYPES_TO_LOG.include? actionType

    meta['appVersion'] ||= appVersion
    meta['osVersion'] ||= osVersion
    line_data = Hash.new
    line_data['error'] = nil
    line_data['line'] = index+1 
    line_data['time'] = time
    line_data['actionType'] = actionType

    action_props = action.split('::').map{|prop| prop.split(':', 2)}
    if action_props.length > 1 
      action_props.each{|p| line_data[p.first.strip] = p.last.strip}
    else
      line_data['value'] = action_props.flatten.join
    end
    line_data['error'] = '☑' if actionType == 'ERROR' || 
                                (!line_data['responseStatus'].nil? && line_data['responseStatus'].to_i != 200)
    file_data << line_data
  }
  worksheet.write(0, 1, "Версия iOs: #{meta['osVersion']}")  
  worksheet.write(0, 2, "Версия приложения: #{meta['appVersion']}")

  headers = file_data.map(&:keys).reduce(Set[],:merge)

  headers.each_with_index do |header,index| 

    worksheet.write(row, index, header)
  end
  
  headers = headers.to_a.map.with_index{|item,index| [item,index]}.to_h
  
  row += 1 

  file_data.each do |line|
    line.each {|key,value|
     worksheet.write(row, headers[key], value)
    }
    row += 1
  end

end

workbook.close

File.rename ('output.xlsx'), ('../output.xlsx')