class Isdocker < Formula
  desc "a CLI utility for orchestrating Docker based developer environments"
  homepage "https://github.com/defenseoftheancients/isdocker"
  url "https://github.com/defenseoftheancients/homebrew-isdocker/releases/download/1.0.0/isdocker-x64.tar.gz"
  sha256 "6d368d53d7846b9dcd6fcbd09f9f53c9158023be422a6cd7162e27b5a5f248d1"
  version "1.0.0"
  def install
    bin.install "isdocker"
  end
end