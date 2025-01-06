# spec/system/support/cuprite_setup.rb

# First, load Cuprite Capybara integration
require "capybara/cuprite"

remote_chrome_url = ENV["CHROME_URL"]

# Chrome doesn't allow connecting to CDP by hostnames (other than localhost),
# but allows using IP addresses.
if remote_chrome_url&.match?(/host.docker.internal/)
  require "resolv"

  uri = URI.parse(remote_chrome_url)
  ip = Resolv.getaddress(uri.host)

  remote_chrome_url = remote_chrome_url.sub("host.docker.internal", ip)
end

REMOTE_CHROME_URL = remote_chrome_url
REMOTE_CHROME_HOST, REMOTE_CHROME_PORT =
  if REMOTE_CHROME_URL
    URI.parse(REMOTE_CHROME_URL).yield_self do |uri|
      [uri.host, uri.port]
    end
  end

# Check whether the remote chrome is running and configure the Capybara
# driver for it.
remote_chrome =
  begin
    if REMOTE_CHROME_URL.nil?
      false
    else
      Socket.tcp(REMOTE_CHROME_HOST, REMOTE_CHROME_PORT, connect_timeout: 1).close
      true
    end
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    false
  end

remote_options = remote_chrome ? {url: REMOTE_CHROME_URL} : {}

require "capybara/cuprite"

Capybara.register_driver(:better_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    **{
      window_size: [1200, 800],
      browser_options: remote_chrome ? {"no-sandbox" => nil} : {},
      inspector: true
    }.merge(remote_options)
  )
end

# Configure Capybara to use :better_cuprite driver by default
Capybara.default_driver = Capybara.javascript_driver = :better_cuprite

module CupriteHelpers
  # Drop #pause anywhere in a test to stop the execution.
  # Useful when you want to checkout the contents of a web page in the middle of a test
  # running in a headful mode.
  def pause
    page.driver.pause
  end

  # Drop #debug anywhere in a test to open a Chrome inspector and pause the execution
  def debug(*args)
    page.driver.debug(*args)
  end
end

RSpec.configure do |config|
  config.include CupriteHelpers, type: :system
end
