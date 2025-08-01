class DockerJanitorCli < Formula
  desc "🧼 Clean up dangling Docker resources with preview, stats, and markdown logs"
  homepage "https://github.com/raymonepping/docker-janitor-cli"
  url "https://github.com/raymonepping/homebrew-docker-janitor-cli/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "b01248e97c8fa867b899677d1b07b82d3bcb47e263de22a44ebe098bb5762857"
  license "MIT"
  version "1.0.1"

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
