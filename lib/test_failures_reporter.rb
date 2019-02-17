# frozen_string_literal: true

require 'socket'
require 'json'

class TestFailuresReporter < Minitest::Reporters::BaseReporter
  def start
    puts "Visit #{ENV['REMOTE_REPORTER_URL'].sub('http:', 'https:')}/builds/#{build_id} for details on failures."
    super
  end

  def record(test)
    payload = { class_name: test.klass, name: test.name, time: test.time, result: result(test) }
    if test.failure
      %i(message location backtrace).each { |method| payload["failure_#{method}"] = test.failure.send(method) }
      payload['failure_location'].remove!("#{Rails.root}/")
    end
    remote_report payload, 'rails'
  end

  def report
    send_report
  end

  private

  def build_payload(kind)
    @build_payload ||= {
      build: build_id,
      commit_sha: ENV['HEROKU_TEST_RUN_COMMIT_VERSION'] || `git rev-parse HEAD`.strip,
      branch: ENV['HEROKU_TEST_RUN_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip,
      kind: kind
    }
  end

  def build_id
    @build_id ||= ENV['HEROKU_TEST_RUN_ID'] || SecureRandom.uuid
  end

  def remote_report(payload, kind)
    @test_reports ||= []
    payload = [payload] unless payload.is_a?(Array)
    return if payload.empty?
    @test_reports += payload.map { |test| test.merge(build_payload(kind)) }
    send_report if @last_send.nil? || (Time.now.to_i - @last_send >= 60)
  end

  def send_report
    fire_and_forget_json_post(ENV['REMOTE_REPORTER_URL'], tests: @test_reports)
    @test_reports = []
    @last_send = Time.now.to_i
  end

  def fire_and_forget_json_post(url, body)
    parsed_url = URI.parse(url)
    body = body.to_json
    headers = [
      "POST #{parsed_url.request_uri} HTTP/1.1",
      "Host: #{parsed_url.host}#{":#{parsed_url.port}" if parsed_url.port != 80}",
      'Connection: Close',
      'Content-Type: application/json',
      "Content-Length: #{body.bytesize}"
    ]
    socket = TCPSocket.open(parsed_url.host, parsed_url.port)
    headers.each { |header| socket.puts "#{header}\r\n" }
    socket.puts "\r\n#{body}"
    socket.close
  rescue StandardError => error
    puts("Error while communicating with RemoteReporter: #{error.message}")
    puts(error.backtrace.join("\n"))
  end
end
