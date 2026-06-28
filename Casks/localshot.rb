cask "localshot" do
  version "1.20.2"
  sha256 "737c7e2ee7a02d4aef6b0ab7e31dea9231871efdfb757a61321ca0408de76508"

  url "https://github.com/AkoliteZA/LocalShot/releases/download/v#{version}/LocalShot-v#{version}.zip"
  name "LocalShot"
  desc "Screenshot and screen-recording app"
  homepage "https://github.com/AkoliteZA/LocalShot"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "LocalShot.app"

  uninstall quit: "com.personal.localshot"

  zap trash: [
    "~/Library/Application Support/LocalShot",
    "~/Library/Caches/com.personal.localshot",
    "~/Library/HTTPStorages/com.personal.localshot",
    "~/Library/Preferences/com.personal.localshot.plist",
    "~/Library/Saved Application State/com.personal.localshot.savedState",
  ]

  caveats <<~EOS
    Current LocalShot builds are ad-hoc signed and not Apple-notarized. If macOS
    blocks the first launch, open LocalShot once from Finder with Control-click >
    Open.
  EOS
end
