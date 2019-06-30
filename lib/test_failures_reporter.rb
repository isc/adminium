# frozen_string_literal: true

require 'socket'
require 'json'

class TestFailuresReporter < Minitest::Reporters::BaseReporter
  def start
    puts "Visit #{ENV['REMOTE_REPORTER_URL']}/builds/#{build_id} for details on failures."
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

  def remote_report(test_payload, kind)
    @test_reports ||= []
    @test_reports.push test_payload.merge(build_payload(kind))
    send_report if @last_send.nil? || (@last_send < 60.seconds.ago)
  end

  def send_report
    HTTParty.post ENV['REMOTE_REPORTER_URL'], body: { tests: @test_reports }
    @test_reports = []
    @last_send = Time.current
  end
end
