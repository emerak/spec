require File.expand_path('../../../spec_helper', __FILE__)

describe "Time#yday" do
  it "returns an integer representing the day of the year, 1..366" do
    with_timezone("UTC") do
      Time.at(9999999).yday.should == 116
    end
  end

  it 'returns the correct value for each day of each month' do
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    previous = 0
    days.each_with_index do |days, month|
      days.times do |day|
        yday = Time.new(2014, month+1, day+1).yday
        yday.should == previous+1
        previous = yday
      end
    end
  end
end
