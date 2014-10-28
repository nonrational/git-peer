require "git/peer"

describe Git::Peer do
  it "explodes with no constructor arguments" do
    expect { Git::Peer.new }.to raise_error(ArgumentError)
  end
end
