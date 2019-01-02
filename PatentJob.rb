require 'csv'
require 'net/ftp'

class PatentJob
  attr_reader :downloader

  def initialize(config: Config.new(filename:'patent.yml'), downloader: config.downloader_class.constantize.new(config))
    @downloader = downloader
  end

  def run
    temp =  downloader.download_file
    rows = parse(temp)
    update_patents(rows)
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

class FtpDownloader
  attr_reader :config

  def initialize(config)
    @config = config
  end
  def download_file
    temp = Tempfile.new(config.ftp_filename)
    tempname = temp.path
    temp.close
    Net::FTP.open(config.ftp_host,config.ftp_login, config.ftp_password) do |ftp|
      ftp.getbinaryfile(join(config.ftp_path, config.ftp_filename), tempname)
    end
    tempname
  end
end

class Config
  attr_reader :data, :env
  def self.config_path
    File.join('config', 'external_resources')
  end

  def initialize(env: Rails.env, filename:)
    @data = YAML::load_file(File.join(self.class.config_path, filename))
    define_methods_for_environmment(data[env].keys)
  end

  def define_methods_for_environment(names)
    names.each do |name|
      class_eval <<-EOS
          def #{name}       #def ftp_host
            data[env]['#{name}']    #data[env]['ftp_host']
          end               # end  
        EOS
    end
  end
end
