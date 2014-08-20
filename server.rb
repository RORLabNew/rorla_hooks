require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra/base'
require 'sinatra/json'
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
  helpers Sinatra::JSON

  get '/' do
    json({ 
      'text' => '배포 테스트 ~!' 
    })
  end

  post '/reload' do
    if params['token'] != ENV['API_TOKEN']
      json({
        'text' => '잘못된 요청'
      })
    else
      exist_container = Docker::Container.get('rorla-latest')
      exist_container.stop
      exist_container.delete

      new_container = Docker::Container.create(
        'name' => 'rorla-latest',
        'Image' => 'rorla/rorla',
        'Env' => [
          "SECRET_KEY_BASE=#{ENV['SECRET_KEY_BASE']}",
          "MANDRILL_USERNAME=#{ENV['MANDRILL_USERNAME']}",
          "MANDRILL_APIKEY=#{ENV['MANDRILL_APIKEY']}",
          "RORLA_HOST=#{ENV['RORLA_HOST']}",
          "RORLA_LOGENTRIES_TOKEN=#{ENV['RORLA_LOGENTRIES_TOKEN']}"
        ]
      )

      new_container.start(
        'Links' => ['mysql:mysql'],
        'VolumesFrom' => ['rorla_uploads'],
        'PortBindings' => {
          '80/tcp' => [{ 
            'HostIp' => '0.0.0.0',
            'HostPort' => '80'
          }]
        }
      )

      json({
        'text' => new_container.json
      })
    end
  end
end

server = ::Rack::Handler::WEBrick
trap(:INT) do
  server.shutdown
end
server.run(MyServer, webrick_options)
