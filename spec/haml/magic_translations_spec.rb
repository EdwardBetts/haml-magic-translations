# -*- coding: UTF-8 -*-

require 'spec_helper'
require 'tmpdir'
require 'gettext/tools'

# Stolen from ActiveSupport. We have to cut and paste it here so it
# does not turn the encoding back to US-ASCII. Strange issue.
class String
  unless String.method_defined? :try
    def try(*args)
      send(*args) if respond_to?(args.first)
    end
  end

  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end

  def translate_unicode
    gsub(/\\u([0-9a-z]{4})/) {|s| [$1.to_i(16)].pack("U")}
  end
end

module Haml
  describe MagicTranslations do
    describe '.enable' do
      after { Haml::MagicTranslations.disable }
      context 'when using :i18n as backend' do
        before { Haml::MagicTranslations.enable :i18n }
        it { expect(Haml::MagicTranslations).to be_enabled }
        it { expect(Haml::MagicTranslations::Compiler.
                 magic_translations_helpers).to be == I18n::Gettext::Helpers }
      end
      context 'when using :gettext as backend' do
        before { Haml::MagicTranslations.enable :gettext }
        it { expect(Haml::MagicTranslations).to be_enabled }
        it { expect(Haml::MagicTranslations::Compiler.
               magic_translations_helpers).to be == GetText }
      end
      context 'when using :fast_gettext as backend' do
        before { Haml::MagicTranslations.enable :fast_gettext }
        it { expect(Haml::MagicTranslations).to be_enabled }
        it { expect(Haml::MagicTranslations::Compiler.
               magic_translations_helpers).to be == FastGettext::Translation }
      end
      context 'when giving another backend' do
        it 'should raise an error' do
          expect {
            Haml::MagicTranslations.enable :whatever
          }.to raise_error(ArgumentError)
        end
        it { expect(Haml::MagicTranslations).to_not be_enabled }
      end
    end

    describe '.disable' do
      it 'should set Haml::MagicTranslations.enabled to false' do
        Haml::MagicTranslations.disable
        expect(Haml::MagicTranslations).to_not be_enabled
      end
    end

    shared_examples 'Haml magic translations' do
      it 'should translate text using existing locales' do
        expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
          %p Magic translations works!
          %p Here with interpolation, and everything thanks to #{I18n.name} and #{GetText.name}
        HAML
          <p>Magiczne tłumaczenie działa!</p>
          <p>A tutaj razem z interpolacją, a to wszystko dzięki połączeniu I18n i GetText</p>
        HTML
      end

      it 'should leave text without changes when translation is not available' do
        expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
          %p Untranslated thanks to #{I18n.name} and #{GetText.name}
        HAML
          <p>Untranslated thanks to I18n and GetText</p>
        HTML
      end

      it 'should translate text with multiline plain text' do
       expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
          %p Magic translations works!
          %p
            Now we will check multiline strings,
            which should be also translated,
            with interpolation #{'Interpolation'.upcase}
        HAML
          <p>Magiczne tłumaczenie działa!</p>
          <p>
            Kolejny wieloliniowy tekst,
            który powinien zostać przetłumaczony,
            interpolacja INTERPOLATION też działa!
          </p>
        HTML
      end

      it 'should translate escaped tags' do
        expect(render(<<-HAML.strip_heredoc)).to be == <<-HTML.strip_heredoc
          %p& Magic translations works!
        HAML
          <p>Magiczne tłumaczenie działa!</p>
        HTML
      end

      it 'should translate unescaped tags' do
        expect(render(<<-HAML.strip_heredoc)).to be == <<-HTML.strip_heredoc
          %p! Magic translations works!
        HAML
          <p>Magiczne tłumaczenie działa!</p>
        HTML
      end

      it 'should not translate evaluated tags' do
        expect(render(<<-HAML.strip_heredoc)).to be == <<-HTML.strip_heredoc
          %p= 'Magic translations works!'
        HAML
          <p>Magic translations works!</p>
        HTML
      end

      it 'should not translate escaped evaluated tags' do
        expect(render(<<-HAML.strip_heredoc)).to be == <<-HTML.strip_heredoc
          %p&= 'Magic translations works!'
        HAML
          <p>Magic translations works!</p>
        HTML
      end

      it 'should not translate unescaped evaluated tags' do
        expect(render(<<-HAML.strip_heredoc)).to be == <<-HTML.strip_heredoc
          %p!= 'Magic translations works!'
        HAML
          <p>Magic translations works!</p>
        HTML
      end

      context 'when translating strings in JavaScript' do
        it "should translate strings inside _('')" do
          expect(render(<<-'HAML'.strip_heredoc).translate_unicode).to be == <<-'HTML'.strip_heredoc.translate_unicode
            :javascript
              var text = _('Magic translations works!');
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "Magiczne t\u0142umaczenie dzia\u0142a!";
              //]]>
            </script>
          HTML
        end
        it 'should translate strings inside _("")' do
          expect(render(<<-'HAML'.strip_heredoc).translate_unicode).to be == <<-'HTML'.strip_heredoc.translate_unicode
            :javascript
              var text = _("Magic translations works!");
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "Magiczne t\u0142umaczenie dzia\u0142a!";
              //]]>
            </script>
          HTML
        end
        it 'should not choke on single-quote' do
          expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
            :javascript
              var text = _("Don't you think?");
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "Don't you think?";
              //]]>
            </script>
          HTML
        end
        it 'should not choke on double-quote' do
          expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
            :javascript
              var text = _('One "quote" here');
          HAML
            <script type='text/javascript'>
              //<![CDATA[
                var text = "One \"quote\" here";
              //]]>
            </script>
          HTML
        end
      end

      context 'when translating strings in Markdown' do
        it "should translate strings inside _('')" do
          expect(render(<<-'HAML'.strip_heredoc).lstrip).to be == <<-'HTML'.strip_heredoc
            :maruku
              Now we will check multiline strings,
              which should be also translated.
          HAML
            <p>Kolejny wieloliniowy tekst, który powinien zostać przetłumaczony.</p>
          HTML
        end
      end

      context 'when disabling magic translations' do
        it 'should leave text untranslated' do
          Haml::MagicTranslations.disable
          expect(render(<<-'HAML'.strip_heredoc)).to be == <<-'HTML'.strip_heredoc
            %p Magic translations works!
          HAML
            <p>Magic translations works!</p>
          HTML
        end
      end
    end

    context 'with I18n as backend' do
      before(:each) do
        Haml::MagicTranslations.enable :i18n
        I18n.config.enforce_available_locales = false
        I18n.locale = :pl
        I18n.load_path += Dir[File.join(File.dirname(__FILE__), "../locales/*.po")]
      end
      it_should_behave_like 'Haml magic translations'
    end

    context 'with GetText as backend' do
      # set up locales file as GetText expects
      around do |example|
        Dir.mktmpdir("haml-magic-translations") do |tmpdir|
          src_dir = File.expand_path('../../locales', __FILE__)
          Dir.glob(File.join(src_dir, '*.po')).each do |src|
            lang = File.basename(src).gsub(/\.po$/, '')
            dest = File.join(tmpdir, lang, 'LC_MESSAGES', 'test.mo')
            FileUtils.mkdir_p(File.dirname(dest))
            GetText::Tools::MsgFmt.run(src, '-o', dest)
          end
          Haml::MagicTranslations.enable :gettext
          GetText.bindtextdomain 'test', :path => tmpdir
          GetText.set_locale 'pl'
          example.run
        end
      end
      it_should_behave_like 'Haml magic translations'
    end

    context 'with FastGettext as backend' do
      # set up locales file as FastGettext expects
      around do |example|
        Dir.mktmpdir("haml-magic-translations") do |tmpdir|
          src_dir = File.expand_path('../../locales', __FILE__)
          Dir.glob(File.join(src_dir, '*.po')).each do |src|
            lang = File.basename(src).gsub(/\.po$/, '')
            dest = File.join(tmpdir, lang, 'test.po')
            FileUtils.mkdir_p(File.dirname(dest))
            FileUtils.copy(src, dest)
          end
          Haml::MagicTranslations.enable :fast_gettext
          FastGettext.add_text_domain 'test', :path => tmpdir, :type => :po
          FastGettext.text_domain = 'test'
          FastGettext.locale = 'pl'
          example.run
        end
      end
      it_should_behave_like 'Haml magic translations'
    end
  end
end
