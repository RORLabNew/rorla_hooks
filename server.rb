require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

CERT_PATH = '.'

webrick_options = {
  :Port               => 8443,
  :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::INFO),
  :DocumentRoot       => '.',
  :SSLEnable          => true,
  :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate     => OpenSSL::X509::Certificate.new(File.open(File.join(CERT_PATH, "server.crt")).read),
  :SSLPrivateKey      => OpenSSL::PKey::RSA.new(File.open(File.join(CERT_PATH, "server.key")).read),
  :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ]
}

class MyServer < Sinatra::Base
  get '/' do
    "rorla deploy hook!\n"
  end

  post '/reload' do
    result = system('/app/rorla_reload.sh')
    p "result => #{result}\n"
    "result => #{result}\n"
  end
end

server = ::Rack::Handler::WEBrick
trap(:INT) do
  server.shutdown
end
server.run(MyServer, webrick_options)
