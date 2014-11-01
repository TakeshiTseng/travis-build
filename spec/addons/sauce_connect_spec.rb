require 'spec_helper'

describe Travis::Build::Script::Addons::SauceConnect, :sexp do
  let(:config)  { '9.3' }
  let(:data)    { PAYLOADS[:push].deep_clone }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:addon)   { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject       { sh.to_sexp }
  before        { addon.before_script }

  shared_examples_for 'starts sauce connect' do
    it { should include_sexp [:echo, 'Starting Sauce Connect', ansi: :yellow] }
    it { should include_sexp [:cmd, 'curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash'] }
    it { should include_sexp [:export, ['TRAVIS_SAUCE_CONNECT', 'true']] }
  end

  describe 'without credentials' do
    let(:config) { {} }

    it_behaves_like 'starts sauce connect'
  end

  describe 'with username and access key' do
    let(:config) { { :username => 'username', :access_key => 'access_key' } }

    it { should include_sexp [:export, ['SAUCE_USERNAME', 'username']] }
    it { should include_sexp [:export, ['SAUCE_ACCESS_KEY', 'access_key']] }

    it_behaves_like 'starts sauce connect'
  end
end
