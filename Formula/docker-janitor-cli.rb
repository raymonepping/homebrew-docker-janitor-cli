class DockerJanitorCli < Formula
  desc "🧼 Clean up dangling Docker resources with preview, stats, and markdown logs"
  homepage "https://github.com/raymonepping/docker-janitor-cli"
  url "https://github.com/raymonepping/homebrew-docker-janitor-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "81f0012ea24c2ac9c564e6181a9755543fd2279f0c15e9a10755b4bc8d09607e"
  license "MIT"
  version "1.0.0"

  depends_on "bash"
  depends_on "jq"
  depends_on "coreutils"

  def install
    bin.install "bin/docker_janitor" => "docker_janitor"
    lib.install Dir["lib/*"]
  end

  def caveats
    <<~EOS
      🧽 Get started with:
        docker_janitor --help

      🔍 Features:
        • --dryrun (default): Show what would be removed
        • --force: Actually remove images, containers, volumes, etc.
        • --scope: 'safe' or 'deep' cleanup levels
        • --stats: Show disk usage delta
        • --dryrun-summary: Export analysis to timestamped Markdown
        • --log FILE: Write live cleanup summary

      📁 Logs are saved to ./logs/ by default (created automatically).
      📚 Full docs: https://github.com/raymonepping/homebrew-docker-janitor-cli
    EOS
  end

  test do
    assert_match "Usage", shell_output("#{bin}/docker_janitor --help")
  end
end
