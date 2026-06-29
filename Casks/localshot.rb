cask "localshot" do
  version "1.20.3"
  sha256 "e386a1c0f332dd432c18664bfc4b052f0bc3fedc38fb216bc5a809269510da4e"

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
