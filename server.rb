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
    begin
      if params['token'] != ENV['API_TOKEN']
        json({
          'text' => '잘못된 요청'
        })
      else
        # pull latest image
        Docker::Image.create('fromImage' => 'rorla/rorla', 'tag' => 'latest')

        # stop exist container
        begin
          exist_container = Docker::Container.get('rorla-latest')
          exist_container.stop
          exist_container.delete
        rescue Docker::Error::NotFoundError => e
          puts '기존에 생성된 컨테이너 없음'
        end
        
        # create new container
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

        # run new container
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

        container_info = new_container.json

        json({
          'text' => "#{container_info['Name']} container launch. #{container_info['State']}"
        })
      end
    rescue Exception => e
      json({
        'text' => "에러 발생. #{e}"
      })
    end
  end
end

server = ::Rack::Handler::WEBrick
trap(:INT) do
  server.shutdown
end
server.run(MyServer, webrick_options)
