require 'csv'
require 'net/ftp'

class PatentJob

  def run
    temp = download_file
    rows = parse(temp)
    update_patents(rows)
  end

  def download_file
    temp = Tempfile.new('patents')
    tempname = temp.path
    temp.close
    Net::FTP.open('localhost','foo', 'foopw') do |ftp|
      ftp.getbinaryfile('Public/prod/patents.csv', tempname)
    end
    tempname
  end

  def parse(temp)
    CSV.read(temp, :headers => true)
  end

  def update_patents(rows)
    Patent.connection.transaction {
      Patents.delete_all
      rows.each {|r| Patent.create!(r.to_hash)}
    }
  end

end
