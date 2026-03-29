class Pgpeek < Formula
  desc "Minimal PostgreSQL GUI client"
  homepage "https://github.com/supergrow-ai/pgpeek"
  url "https://github.com/supergrow-ai/pgpeek.git", tag: "v0.1.0"
  license "MIT"

  def install
    # Only copy source files — build deferred to first run
    libexec.install Dir["*"]
    libexec.install Dir[".*"].reject { |f| ["..", "."].include?(File.basename(f)) }

    (bin/"pgpeek").write <<~EOS
      #!/usr/bin/env bash
      set -e

      # Ensure node and pnpm are available
      command -v node >/dev/null 2>&1 || { echo "Error: node is required. Install it via fnm, nvm, or brew."; exit 1; }
      command -v pnpm >/dev/null 2>&1 || { echo "Error: pnpm is required. Install it via: npm i -g pnpm"; exit 1; }

      cd "#{libexec}"

      if [ ! -d ".next" ]; then
        echo "Setting up pgpeek (first run)..."
        pnpm install --frozen-lockfile
        pnpm build
        echo ""
      fi

      node -e "require('better-sqlite3')" 2>/dev/null || {
        echo "Rebuilding native modules for $(node --version)..."
        pnpm rebuild better-sqlite3
      }

      PORT="${PORT:-3000}"
      while lsof -i :"$PORT" >/dev/null 2>&1; do
        PORT=$((PORT + 1))
      done
      echo "Starting pgpeek on http://localhost:$PORT"
      (sleep 2 && open "http://localhost:$PORT" 2>/dev/null || true) &
      exec pnpm start -p "$PORT"
    EOS
  end

  test do
    assert_match "pgpeek", shell_output("cat #{libexec}/package.json")
  end
end
