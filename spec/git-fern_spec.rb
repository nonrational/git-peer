require "git/fern"

describe Git::Fern do
  it "explodes with no constructor arguments" do
    expect { Git::Fern.new }.to raise_error(ArgumentError)
  end
end
