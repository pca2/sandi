require 'minitest/autorun';
require_relative 'PatentJob';

describe PatentJob do
  it "should download csv file from ftp server " do
    upload_test_file('localhost','foo', 'foopw', 'patents.csv','Public/test')
    @conn = PatentDownloader.new
    f = File.read(@conn.download_file)
    f.should have(250).characters
    f.include?("just 3 minutes").should be_true
  end

  it "should replace existing patents with new patents" do
    downldr = mock("Downloader")
    f = fixture_path + '/patents.csv'
    downldr.should_receive(:download_file).once.and_return(f)
    @job = PatentJob.new
    @job.run
    Patent.find(:all).should have(3).rows
    Patent.find_by_name("Anti-Gravity Simulator").should be
    Patent.find_by_name("Exo-Skello Jello").should be
    Patent.find_by_name("Nap Compressor").should be
  end
end
